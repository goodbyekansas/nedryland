{ base, pkgs }:
let
  component = import ../../languages/rust/protobuf/compiler {
    mkClient = base.languages.rust.mkClient;
    protobuf = pkgs.protobuf;
  };
in
(component // { path = ../../languages/rust/protobuf/compiler; })
