{ base }:

# Simple component with single deployment
base.mkComponent rec {
  name = "single";
  src = ./.;

  deployment = {
    artifact = base.deployment.mkDeployment {
      name = "single-deploy";

      # Note that these deploy scripts do not run when you build your component.
      # What nix does is generate a deploy script and puts it in your output folder.

      # You will then have to run the deploy script manually. This might
      # seem like doing something with extra steps but there are good reasons.
      # Nix needs to be pure in its state and environment.
      # Deploying by nature is un-pure. You will need things pointing to global
      # reasources such as urls pointing to package repositories or addresses
      # and passwords for databases.
      preDeployPhase = ''
        echo "Setting up super important things before deployment!"
      '';

      deployPhase = ''
        echo "Deploying ${name}.."
      '';

      postDeployPhase = ''
        echo "Cleaning up state after my awesome deployment!"
      '';

      # You can try the following commands.
      # `nix build -f default.nix singleDeployment.deploy`
      # This will build the derivation and it will end up in ./result/bin/deploy
      # Try running `./result/bin/deploy`

      # If you want to end up in a shell where you can work with your deployment
      # you can instead call `./result/bin/shell
      # If you only run `./result/bin/shell` it will run preDeployPhase to set up your shell
      # so you can work in the deployment environment.
    };
  };
}
