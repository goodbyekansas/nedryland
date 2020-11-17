{ rust, protobuf }:
rust.mkClient {
  name = "rust-protobuf-compiler";
  src = ./.;
  PROTOC = "${protobuf}/bin/protoc";
  externalDependenciesHash = "sha256-63589VnzjTcqUmw330pAtu+tJkx+n1RLIPhAtBZFrnk=";
}
