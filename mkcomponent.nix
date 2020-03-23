pkgs: protoLocation: { package, deployment ? {}, docs ? null, usesProtobuf ? true }:
let
  packageWithProto = package.overrideAttrs (
    oldAttrs: {
      # this is needed on NixOS but does not hurt on other
      # OSes either
      PROTOC = "${pkgs.protobuf}/bin/protoc";
      PROTOBUF_DEFINITIONS_LOCATION = protoLocation;
      shellHook = ''
        ${oldAttrs.shellHook or ""}
        export PROTOBUF_DEFINITIONS_LOCATION=${protoLocation}
      '';
    }
  );
in
rec { package = if usesProtobuf then packageWithProto else package; inherit deployment docs; }
