base: lib:
let
  combineDocs = attrs: api: ({
    inherit api;
  } // attrs.docs or { });

  docsConfig = (lib.filterAttrs (_: v: v != "" && v != [ ]) (base.parseConfig {
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
      name = "sphinx4_rtd_theme";
      conf = "html_theme = \\\"sphinx_rtd_theme\\\"";
    };
  }."${docsConfig.python.sphinx-theme}" or null;

  componentConfig = (lib.filterAttrs (_: v: v != "") (base.parseConfig {
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
  __functor = self: self."${docsConfig.python.generator}";

  sphinx = attrs@{ name, src, pythonVersion, ... }: combineDocs attrs (base.mkDerivation {
    inherit src;
    name = "${name}-api-reference";
    nedrylandType = "documentation";
    buildInputs = [ pythonVersion.pkgs.sphinx4 ] ++ lib.optional (sphinxTheme != null) pythonVersion.pkgs."${sphinxTheme.name}"
      ++ (attrs.buildInputs or (_: [ ]) pythonVersion.pkgs) ++ (attrs.propagatedBuildInputs or (_: [ ]) pythonVersion.pkgs);
    srcFilter = path: type: (
      builtins.match ".*\.py" (baseNameOf path) != null
    )
    && baseNameOf path != "setup.py"
    || type == "directory";
    configurePhase = ''
      sphinx-apidoc \
        --full \
        --follow-links \
        --append-syspath \
        -H "${name}" \
        ${lib.optionalString (attrs ? version) "-V ${attrs.version}"} \
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
      mkdir -p $out/share/doc/api/${name}
      cp -r _build/html/. $out/share/doc/api/${name}
    '';
  });

  pdoc = attrs@{ name, src, pythonVersion, ... }: combineDocs attrs (base.mkDerivation {
    inherit src;
    name = "${name}-api-reference";
    nedrylandType = "documentation";
    buildInputs = [ pythonVersion.pkgs.pdoc ]
      ++ ((attrs.buildInputs or (_: [ ])) pythonVersion)
      ++ (attrs.propagatedBuildInputs or (_: [ ])) pythonVersion;
    nativeBuildInputs = ((attrs.nativeBuildInputs or (_: [ ])) pythonVersion);
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
      mkdir -p $out/share/doc/api/${name}
      cp -r docs $out/share/doc/api/${name}
      ${if logo ? source then "cp ${logo.source} $out/share/doc/api/${name}/${logo.path}" else ""}
    '';
  });
}
