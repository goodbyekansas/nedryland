(import ../default.nix).mkProject {
  name = "deployment";
  components = { callFile }: rec {
    terraform = callFile ./terraform/deployer.nix { };
  };
}
