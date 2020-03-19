pkgs:

pkgs.stdenv.mkDerivation {
  name = "aves-theme-css";
  src = ./.;
  buildInputs = with pkgs; [
    nodePackages.yarn
  ];

  configurePhase = ''
    export HOME=$PWD
    yarn install
  '';

  buildPhase = ''
    yarn run sass --source-map-urls relative --embed-sources -I node_modules src/main.scss ./out/main.css
  '';

  installPhase = ''
    mkdir -p $out/css/
    mkdir -p $out/scss/
    cp -r ./out/* $out/css

    cp -r node_modules/bulma $out/scss
    cp -r node_modules/nord $out/scss

    cp -r src/* $out/scss
  '';
}
