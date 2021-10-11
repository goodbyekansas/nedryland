{ base, pkgs }:
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
  projectGenerator = ./. + "/${docsConfig.markdown.htmlGenerator}.nix";
in
rec {
  mkProjectDocs =
    assert pkgs.lib.assertMsg (docsConfig.markdown ? htmlGenerator) ''Config does not have a "htmlGenerator" set in the [docs.markdown] section'';
    assert pkgs.lib.assertMsg (builtins.pathExists projectGenerator) ''Invalid docs generator, options are: mdbook, mkdocs'';
    import projectGenerator pkgs base;
  mkMdbook = import ./mdbook.nix pkgs base;
  mkDocs = import ./mkdocs.nix pkgs base;
}
