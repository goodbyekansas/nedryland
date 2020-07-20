{ base, pkgs }:
{
  rust = pkgs.callPackage ./rust { inherit base; };
  python = pkgs.callPackage ./python { inherit base; };
}
