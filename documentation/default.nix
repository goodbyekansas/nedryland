pkgs: base:
let
  docsConfig = pkgs.lib.filterAttrs (_: v: v != "" && v != [ ]) (base.parseConfig {
    key = "docs";
    structure = {
      markdown = {
        htmlGenerator = "";
      };
      author = "";
      authors = [ ];
      language = "en";
    };
  });
in

builtins.mapAttrs
  (_: f: attrs: {
    docfunction = name: type: (f ({ inherit name type; } // attrs));
  })
rec {
  mkProjectDocs =
    assert pkgs.lib.assertMsg (docsConfig.markdown ? htmlGenerator) ''Config does not have a "htmlGenerator" set in the [docs.markdown] section'';
    assert pkgs.lib.assertMsg (builtins.elem docsConfig.markdown.htmlGenerator [ "mdbook" "mkdocs" ]) ''Invalid docs generator, options are: mdbook, mkdocs'';
    if docsConfig.markdown.htmlGenerator == "mdbook" then mkMdbook else mkDocs;

  mkMdbook = import ./mdbook.nix pkgs base;

  mkDocs = import ./mkdocs.nix pkgs base;

  mkSinglePage = args@{ name, src, type ? "user", ... }: base.mkDerivation {
    inherit name src;
    nativeBuildInputs = [ pkgs.python3.pkgs.markdown ];
    phases = [ "buildPhase" "installPhase" ];

    buildPhase = ''
      runHook preBuild
      python -m markdown --output_format=html --file=$name.html $src
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/doc/$name/${type}
      cp $name.html $out/share/doc/$name/${type}/index.html
      runHook postInstall
    '';

    shellCommands = {
      run = "eval $buildPhase && xdg-open $name.html";
    } // args.shellCommands or { };
  };
}
