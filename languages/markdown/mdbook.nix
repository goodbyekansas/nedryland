pkgs: base: attrs@{ name, ... }:
let
  bookToml = attrs:
    let
      options = pkgs.lib.optional (attrs ? language) "language = \"${attrs.language}\""
        ++ pkgs.lib.optional (attrs ? title) "title = \\\"${attrs.title}\\\""
        ++ pkgs.lib.optional (attrs ? author) "author = \\\"${attrs.author}\\\""
        ++ pkgs.lib.optional (attrs ? authors) "authors = [${builtins.concatStringsSep ", " (builtins.map (v: "\\\"${v}\\\"") attrs.authors)}]"
        ++ pkgs.lib.optional (attrs ? description) "description = \\\"${attrs.description}\\\"";
    in
    ''
      [book]
      ${builtins.concatStringsSep "\n" options}
    '';
in
base.mkComponent {
  inherit name;
  nedrylandType = attrs.nedrylandType or "documentation";
  package = pkgs.stdenv.mkDerivation (attrs // {
    name = "${name}-package";
    buildInputs = [ pkgs.mdbook ];
    unpackPhase = ''
      if [ -d $src ]; then
        ln -s $src src
      else
        mkdir src
        ln -s $src ./src/README.md
        echo "# $name
        - [$name](./README.md)" > ./src/SUMMARY.md
      fi
    '';
    configurePhase = ''
      echo "${bookToml attrs}" > book.toml
    '';
    buildPhase = ''
      mdbook build
    '';
    installPhase = ''
      cp -r book $out
    '';
    shellHook = ''
      preview() {
        mdbook serve --port ''${1:-3000} &
      }

      echo -e "Use \033[1mpreview\033[0m to look at the book in a webbrowser, which updates on file save"
      ${attrs.shellHook or ""}
    '';
  });
}
