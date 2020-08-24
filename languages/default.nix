{ base, pkgs }:
{
  rust = pkgs.callPackage ./rust { inherit base; };
  python = pkgs.callPackage ./python { inherit base; };
  terraform = pkgs.callPackage ./terraform { inherit base; };
}
