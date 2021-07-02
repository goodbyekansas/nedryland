{ base, python3, baseProtocols }:
base.languages.protobuf.mkModule {
  name = "ext";
  version = "1.0.0";
  src = ./.;
  languages = [ base.languages.python base.languages.rust ];
  protoInputs = [ baseProtocols ];
  pythonVersion = python3;
}
