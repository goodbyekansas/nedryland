let
  nedryland = import ../../default.nix;
  project = nedryland.mkProject {
    name = "hello-example";
    configFile = ./config.toml;
  };
in
project.mkGrid {
  # The keys in the components set are used to depend on or reference components
  # they declare their actual name in their respective nix files
  components = rec {
    # Library for advanced math functions
    numpyWrapper = project.declareComponent ./utils/numpy-wrapper/numpy-wrapper.nix { };
    # Client that uses the above library to print a message
    pythonHello = project.declareComponent ./clients/hello/hello.nix { numpyWrapper = numpyWrapper.package; };
  };
  deploy = { };
}
