pkgs: base: attrs@{ name, ... }:
base.mkComponent {
  inherit name;
  nedrylandType = attrs.nedrylandType or "documentation";
  package = base.mkDerivation {
    name = "${name}-package";
    src = attrs.src;
    buildInputs = [ pkgs.mkdocs ];

    buildPhase = ''
      mkdocs build --verbose
    '';
    installPhase = ''
      mkdir -p $out/share/doc/${name}
      cp -r site/. $out/share/doc/${name}
    '';
    shellHook = ''
      preview() {
        mkdocs serve &
      }

      echo -e "Use \033[1mpreview\033[0m to look at the docs in a webbrowser, which updates on file save"
    '';
  };
}
