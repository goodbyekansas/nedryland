{ base, pkgs }:
let
  all = rec {
    rust = pkgs.callPackage ./rust { inherit base; };
    python = pkgs.callPackage ./python { inherit base; };
    terraform = pkgs.callPackage ./terraform { inherit base; };
  };
  allWithProto = (all // { protobuf = pkgs.callPackage ./protobuf { languages = all; }; });
in
(builtins.mapAttrs (name: value: (value // { inherit name; })) allWithProto)
