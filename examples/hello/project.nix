{ nedryland, pkgs }:
(nedryland { inherit pkgs; }).mkProject {
  name = "hello-example";
  configFile = ./hello.toml;

  # The keys in the components set are used to depend on or reference components
  # they declare their actual name in their respective nix files
  components = { callFile }: {
    # Library that prints greetings in different languages
    greeting = callFile ./libraries/greeting/greeting.nix { };

    # Client that uses the above library to print a message
    hello = callFile ./clients/hello/hello.nix { };

    # A sample for deploying a single component.
    singleDeployment = callFile ./deployment/single.nix { };

    # A component with a combined deployment.
    combinedDeployment = callFile ./deployment/combined.nix { };

    # sources are filtered with git ignore, these two contains different files but after
    # git ignore they are the same
    sameThing1 = callFile ./libraries/same-things-1/same-thing.nix { };
    sameThing2 = callFile ./libraries/same-things-2/same-thing.nix { };
  };
}
