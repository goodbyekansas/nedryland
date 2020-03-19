pkgs:

pkgs.stdenv.mkDerivation {
  name = "fonts";
  src = ./.;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out;
    cp -ra $src/fonts/* $out
  '';
}
