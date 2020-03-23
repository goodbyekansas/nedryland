{ base, pkgs }:
{ rust = pkgs.callPackage ./rust { inherit base; }; }
