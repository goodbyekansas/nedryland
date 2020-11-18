{ base, pkgs }:
base.languages.protobuf.mkModule {
  name = "base";
  version = "0.1.0";
  src = ./.;
  languages = [ base.languages.python base.languages.rust ];
  pythonVersion = pkgs.python3;
}
