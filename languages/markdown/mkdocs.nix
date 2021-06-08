pkgs: base: attrs@{ name, ... }:
base.mkComponent {
  inherit name;
  nedrylandType = attrs.nedrylandType or "documentation";
  package = pkgs.stdenv.mkDerivation {
    name = "${name}-package";
    src = attrs.src;
    buildInputs = [ pkgs.mkdocs ];
    unpackPhase = ''
      echo $src
      if [ -d $src ]; then
        ln -s $src/* .
      else
        mkdir docs
        ln -s $src docs/index.md
        echo "site_name: ${name}
          nav:
              - Home: index.md" > mkdocs.yml
      fi
    '';
    buildPhase = ''
      mkdocs build --verbose
    '';
    installPhase = ''cp -r site $out'';
    shellHook = ''
      preview() {
        mkdocs serve &
      }

      echo -e "Use \033[1mpreview\033[0m to look at the docs in a webbrowser, which updates on file save"
    '';
  };
}
