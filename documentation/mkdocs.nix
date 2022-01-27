pkgs: base: attrs@{ name, src, type ? "user", ... }:
base.mkDerivation (attrs // {
  inherit name src;

  buildInputs = [ pkgs.mkdocs ];

  buildPhase = ''
    mkdocs build --verbose
  '';
  installPhase = ''
    mkdir -p $out/share/doc/${name}/${type}
    cp -r site/. $out/share/doc/${name}/${type}
  '';
  shellHook = ''
    preview() {
      mkdocs serve &
    }

    echo -e "Use \033[1mpreview\033[0m to look at the docs in a webbrowser, which updates on file save"
  '';
})
