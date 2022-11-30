# numpyWrapper is automatically passed in
# since there is a component with the same name
{ base, python3, numpyWrapper }:

base.languages.python.mkClient {
  name = "hello-nested";
  version = "1.0.0";
  src = ./.;
  pythonVersion = python3;
  # Here we just use numpyWrapper since it's our own
  # package and not part of the python version packages.
  propagatedBuildInputs = (_: [ numpyWrapper.package ]);
}