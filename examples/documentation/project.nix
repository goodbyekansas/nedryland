(import ../../default.nix { }).mkProject {
  name = "documented-project";

  # This config file displays some options for documentation
  configFile = ./conf.toml;

  components = { callFile }: {
    awesomeClient = callFile ./client/client.nix { };
    awesomeWebService = callFile ./service/service.nix { };
  };
  deploy = { deployment, callFile }: components: {
    docs = callFile ./all-docs.nix { inherit components; };
  };
}
