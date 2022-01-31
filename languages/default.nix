pkgs: base: versions:
let
  all = rec {
    rust = pkgs.callPackage ./rust { inherit base versions; };
    python = pkgs.callPackage ./python { inherit base; };
    terraform = pkgs.callPackage ./terraform { inherit base versions; };
  };
  allWithProto = (all // { protobuf = pkgs.callPackage ./protobuf { inherit base; languages = all; }; inherit (pkgs) gitignoreSource; });
in
(builtins.mapAttrs (name: value: (value // { inherit name; })) allWithProto)
