{ base }:
base.mkDerivation {
  name = "same-thing";
  src = ./.;
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup
    ls $src
    mkdir -p $out
    cp $src/same.txt $out/same.txt
  '';
}
