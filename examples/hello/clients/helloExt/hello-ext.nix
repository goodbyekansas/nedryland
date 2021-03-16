{ base }:
# We use our extension that adds numpyWrapper for us
# and sets the pythonVersion
base.languages.python.mkNumpyPython {
  name = "helloExt";
  version = "0.1.0";
  src = ./.;
}
