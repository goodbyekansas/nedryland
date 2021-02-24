# Example project illustrating the protobuf generation functionality in Nedryland
(import ../../default.nix).mkProject {
  name = "protobuf-example";
  components = { callFile }: {
    # expose the compiler here as well so it can be accessed
    compiler = callFile ./compiler.nix { };

    # create a proto module that depends on another one
    baseProtocols = callFile ./protocols/base/protocols.nix { };
    protocols = callFile ./protocols/ext/protocols.nix { };

    client = {
      rust = callFile ./clients/rust/client.nix { };
      python = callFile ./clients/python/client.nix { };
    };
  };
}
