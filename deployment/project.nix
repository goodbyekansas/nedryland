let
  nedryland = import ../default.nix;

  project = nedryland.mkProject {
    name = "deployment";
    configFile = ./config.toml;
  };

in
project.mkGrid {
  components = rec {
    terraform = project.declareComponent ./terraform/deployer.nix { };
  };
  deploy = { };
}
