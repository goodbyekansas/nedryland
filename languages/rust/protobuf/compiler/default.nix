{ mkClient, protobuf }:
mkClient {
  name = "rust-protobuf-compiler";
  src = ./.;
  PROTOC = "${protobuf}/bin/protoc";
}
