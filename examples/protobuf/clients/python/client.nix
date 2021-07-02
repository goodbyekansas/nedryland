{ base, python3, protocols, baseProtocols }:
base.languages.python.mkClient {
  name = "python-client";
  version = "1.0.0";
  pythonVersion = python3;
  propagatedBuildInputs = (pythonPkgs: [ protocols.python.package ]);
  src = ./.;
}
