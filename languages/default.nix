pkgs: base: versions:
let
  all = rec {
    rust = pkgs.callPackage ./rust { inherit base versions; };
    python = pkgs.callPackage ./python { inherit base versions; };
    terraform = pkgs.callPackage ./terraform { inherit base versions; };
  };
  allWithProto = (all // { protobuf = pkgs.callPackage ./protobuf { languages = all; }; });
in
(builtins.mapAttrs (name: value: (value // { inherit name; })) allWithProto)
