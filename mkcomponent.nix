pkgs: attrs@{ package, deployment ? { }, docs ? null, usesProtobuf ? true, ... }:
let
  packageWithProto = package.overrideAttrs (
    oldAttrs: {
      # this is needed on NixOS but does not hurt on other
      # OSes either
      PROTOC = "${pkgs.protobuf}/bin/protoc";
    }
  );
  comp = (
    attrs // {
      package = if usesProtobuf then packageWithProto else package;
      inherit deployment docs;
    }
  );
in
comp
