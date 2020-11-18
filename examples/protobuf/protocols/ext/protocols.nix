{ base, pkgs, baseProtos }:
base.languages.protobuf.mkModule {
  name = "ext";
  version = "0.1.0";
  src = ./.;
  languages = [ base.languages.python base.languages.rust ];
  protoInputs = [ baseProtos ];
  pythonVersion = pkgs.python3;
}
