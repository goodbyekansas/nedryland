{ base, pkgs }:
rec {
  rust = pkgs.callPackage ./rust { inherit base; };
  python = pkgs.callPackage ./python { inherit base; };
  terraform = pkgs.callPackage ./terraform { inherit base; };
  protobuf = pkgs.callPackage ./protobuf { inherit rust python; };
}
