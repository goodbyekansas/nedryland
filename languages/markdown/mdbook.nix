pkgs: base: attrs@{ name, ... }:
base.mkComponent {
  inherit name;
  nedrylandType = attrs.nedrylandType or "documentation";
  package = base.mkDerivation (attrs // {
    name = "${name}-package";
    src = attrs.src;
    buildInputs = [ pkgs.mdbook ];

    buildPhase = ''
      mdbook build --dest-dir book
    '';
    installPhase = ''
      mkdir -p $out/share/doc
      cp -r book/. $out/share/doc/${name}
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
