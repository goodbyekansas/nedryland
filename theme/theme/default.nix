pkgs:
let
  fonts = import ./fonts/default.nix pkgs;
  css = import ./css/default.nix pkgs;
in
pkgs.stdenv.mkDerivation {
  name = "aves-theme";
  phases = [ "installPhase" ];

  buildInputs = [
    fonts
    css
  ];

  # Changing paths will break for example tucan.
  # If you need to remember to change paths in deps
  installPhase = ''
    mkdir -p $out/fonts;
    mkdir -p $out/css;
    mkdir -p $out/scss;
    cp -ra ${fonts}/* $out/fonts
    cp -ra ${css}/css/* $out/css
    cp -ra ${css}/scss/* $out/scss
  '';
}
