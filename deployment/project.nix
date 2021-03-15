(import ../default.nix).mkProject {
  name = "deployment";
  components = { callFile }: {
    terraform = callFile ./terraform/deployer.nix { };
  };
}
