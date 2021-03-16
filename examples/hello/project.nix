(import ../../default.nix).mkProject {
  name = "hello-example";

  # The keys in the components set are used to depend on or reference components
  # they declare their actual name in their respective nix files
  components = { callFile }: {
    # Library for advanced math functions
    numpyWrapper = callFile ./libraries/numpy-wrapper/numpy-wrapper.nix { };
    # Client that uses the above library to print a message
    pythonHello = callFile ./clients/hello/hello.nix { };
    # This client 
    pythonHelloE = callFile ./clients/helloExt/hello-ext.nix { };
  };
  baseExtensions = [
    # We add an extension for making the pythonHello more efficiently
    ./extensions/python-numpywrapped.nix
  ];
}
