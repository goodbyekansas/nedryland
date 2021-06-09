(import ../../default.nix).mkProject {
  name = "hello-example";
  configFile = ./hello.toml;

  # The keys in the components set are used to depend on or reference components
  # they declare their actual name in their respective nix files
  components = { callFile }: {
    # Library for advanced math functions
    numpyWrapper = callFile ./libraries/numpy-wrapper/numpy-wrapper.nix { };
    # Client that uses the above library to print a message
    pythonHello = callFile ./clients/hello/hello.nix { };
    # This client does the same thing as pythonHello but
    # uses the extension (see hello-ext.nix)
    pythonHelloE = callFile ./clients/helloExt/hello-ext.nix { };

    # This is just a sample to show how the interactive shell
    # can help you set up directories etc for new components.
    # Note that author, email and url is taken from the config (./hello.toml).
    shellSetup = callFile ./libraries/interactive-shell-setup/shell-setup.nix { };

    # A sample for deploying a single component.
    singleDeployment = callFile ./deployment/single.nix { };

    # A component with a combined deployment.
    combinedDeployment = callFile ./deployment/combined.nix { };
  };
  baseExtensions = [
    # We add an extension for making the pythonHello more efficiently
    ./extensions/python-numpywrapped.nix
  ];
}
