pkgs: base: attrs@{ name, type ? "user", src, ... }:
base.mkDerivation (attrs // {
  inherit name src;
  buildInputs = [ pkgs.mdbook ];

  buildPhase = ''
    mdbook build --dest-dir book
  '';
  installPhase = ''
    mkdir -p $out/share/doc/${name}/${type}
    cp -r book/. $out/share/doc/${name}/${type}
  '';
  shellCommands = {
    run = ''mdbook serve --port ''${1:-3000} "$@" &'';
  };

  shellHook = ''
    echo -e "Use \033[1mrun\033[0m to look at the book in a webbrowser, which updates on file save"
    ${attrs.shellHook or ""}
  '';
})
