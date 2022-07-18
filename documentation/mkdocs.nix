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
  shellCommands = {
    run = {
      script = ''mkdocs serve "$@" &'';
      description = "Look at the docs in a web browser, which updates on file save";
    };
  } // attrs.shellCommands or { };
})
