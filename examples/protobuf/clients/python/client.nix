{ base, python3, protocols }:
base.languages.python.mkClient {
  name = "python-client";
  version = "1.0.0";
  pythonVersion = python3;
  propagatedBuildInputs = (_: [ protocols.python.package ]);
  src = ./.;
}
