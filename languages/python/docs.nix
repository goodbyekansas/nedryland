pkgs: parseConfig:
let
  combineDocs = attrs: generated: ({
    inherit generated;
  } // attrs.docs or { });

  docsConfig = (pkgs.lib.filterAttrs (k: v: v != "" && v != [ ]) (parseConfig {
    key = "docs";
    structure = {
      python = {
        generator = "sphinx";
        sphinx-theme = "";
      };
      author = "";
      authors = [ ];
      logo = "";
    };
  }));

  sphinxTheme = {
    rtd = {
      name = "sphinx_rtd_theme";
      conf = "html_theme = \\\"sphinx_rtd_theme\\\"";
    };
  }."${docsConfig.python.sphinx-theme}" or null;

  componentConfig = (pkgs.lib.filterAttrs (k: v: v != "") (parseConfig {
    key = "components";
    structure = { author = ""; };
  }));

  author =
    if docsConfig ? authors then
      builtins.concatStringsSep ", " docsConfig.authors
    else if docsConfig ? author then
      docsConfig.author
    else if componentConfig ? author then
      componentConfig.author
    else "Unknown";

  logo =
    if docsConfig ? logo then
      (
        if builtins.pathExists (/. + docsConfig.logo) then {
          source = /. + docsConfig.logo;
          path = "./${builtins.baseNameOf docsConfig.logo}";
        } else { path = docsConfig.logo; }
      ) else { };
in
{
  __functor = self: attrs: self."${docsConfig.python.generator}" attrs;

  sphinx = attrs@{ name, src, pythonVersion, ... }: combineDocs attrs (pkgs.stdenv.mkDerivation {
    name = "${attrs.name}-api-reference";
    nedrylandType = "documentation";
    buildInputs = [ pythonVersion.pkgs.sphinx ] ++ pkgs.lib.optional (sphinxTheme != null) pythonVersion.pkgs."${sphinxTheme.name}"
      ++ (attrs.buildInputs or (_: [ ]) pythonVersion.pkgs) ++ (attrs.propagatedBuildInputs or (_: [ ]) pythonVersion.pkgs);
    src = builtins.filterSource
      (path: type:
        (
          builtins.match ".*\.py" (baseNameOf path) != null
        )
        && baseNameOf path != "setup.py"
        || type == "directory"
      )
      src;
    configurePhase = ''
      sphinx-apidoc \
        --full \
        --follow-links \
        --append-syspath \
        -H "${attrs.name}" \
        -V "${attrs.version}" \
        -A "${author}" \
        -o doc-source \
        .
      
      mkdir -p doc-source
      echo "" >> doc-source/conf.py # generated conf.py does not end in a newline
      ${if sphinxTheme != null then "echo ${sphinxTheme.conf} >> doc-source/conf.py" else "" }
      ${if logo != { } then "echo 'html_logo = \"${logo.source or logo.path}\"' >> doc-source/conf.py" else ""}
    '';
    buildPhase = ''
      cd doc-source
      make html
    '';
    installPhase = ''
      cp -r _build/html $out
    '';
  });

  pdoc = attrs@{ name, pythonVersion, ... }: combineDocs attrs (pkgs.stdenv.mkDerivation {
    name = "${attrs.name}-api-reference";
    nedrylandType = "documentation";
    src = attrs.src;
    buildInputs = [ pythonVersion.pkgs.pdoc ]
      ++ ((attrs.buildInputs or (_: [ ])) attrs.pythonVersion)
      ++ (attrs.propagatedBuildInputs or (_: [ ])) attrs.pythonVersion;
    nativeBuildInputs = ((attrs.nativeBuildInputs or (_: [ ])) attrs.pythonVersion);
    configurePhase = ''
      modules=$(python ${./print-module-names.py})
      ${if logo != { } then "cp -r ${./pdoc-template} ./template" else ""}
      ${if logo != { } then "substituteInPlace ./template/module.html.jinja2 --subst-var-by \"logo\" \"${logo.path}\"" else ""}
      ${if logo != { } then "substituteInPlace ./template/index.html.jinja2 --subst-var-by \"logo\" \"${logo.path}\"" else ""}
    '';
    buildPhase = ''
      pdoc -o docs "$modules" ${if logo != { } then "--template ./template" else ""}
    '';
    installPhase = ''
      cp -r docs $out
      ${if logo ? source then "cp ${logo.source} $out/${logo.path}" else ""}
    '';
  });
}
