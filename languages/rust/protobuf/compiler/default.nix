{ mkClient, protobuf }:
mkClient {
  name = "rust-protobuf-compiler";
  src = ./.;
  PROTOC = "${protobuf}/bin/protoc";
  externalDependenciesHash = "sha256-HYFVW8Du8SKmfSFlMfk/bsLSkEE7bCRpvmyM53L5zLA=";
}
