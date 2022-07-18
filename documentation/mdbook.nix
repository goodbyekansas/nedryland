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
    run = {
      script = ''mdbook serve --port ''${1:-3000} "$@" &'';
      description = ''
        Preview the book and watches the book's src directory for changes, rebuilding the book and refreshing clients for each change.
      '';
    };
  } // attrs.shellCommands or { };
})
