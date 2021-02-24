{ base, python3, protocols, baseProtocols }:
base.languages.python.mkClient {
  name = "python-client";
  version = "0.1.0";
  pythonVersion = python3;
  propagatedBuildInputs = (pythonPkgs: [ protocols.python.package ]);
  src = ./.;
}
