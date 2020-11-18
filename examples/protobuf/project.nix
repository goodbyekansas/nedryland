# Example project illustrating the protobuf generation functionality in Nedryland
let
  nedryland = import ../../default.nix;

  project = nedryland.mkProject {
    name = "protobuf-example";
    configFile = ./config.toml;
  };

in
project.mkGrid {
  components = rec {
    # expose the compiler here as well so it can be accessed
    compiler = project.declareComponent ./compiler.nix { };

    # create a proto module that depends on another one
    baseProtocols = project.declareComponent ./protocols/base/protocols.nix { };
    protocols = project.declareComponent ./protocols/ext/protocols.nix {
      baseProtos = baseProtocols;
    };

    client = {
      rust = project.declareComponent ./clients/rust/client.nix { inherit protocols baseProtocols; };
      python = project.declareComponent ./clients/python/client.nix { inherit protocols baseProtocols; };
    };
  };


  deploy = { };
}
