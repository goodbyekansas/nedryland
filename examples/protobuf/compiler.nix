{ base, pkgs }:
base.callFile ../../languages/rust/protobuf/compiler {
  mkClient = base.languages.rust.mkClient;
  protobuf = pkgs.protobuf;
}
