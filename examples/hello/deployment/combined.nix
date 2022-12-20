{ base }:
# Combined component with single deployment

# The deploy target will combine all members of the deployment set.

# Deployment priority can be set in 3 different ways.
# base.deployment.last which will put it in the back of the list.
# base.deployment.first which will put it first.
# base.deployment.priority which lets you manually set priority

# By default the priority is set to 1000 for all components.
base.mkComponent rec {
  name = "combined";
  src = ./.;

  _default = deployment.lastArtifact;
  deployment = {

    # 3
    # This one will get priority 1000
    anotherArtifact = base.deployment.mkDeployment rec {
      name = "another-artifact";

      deployPhase = ''
        echo "Deploying ${name}.."
      '';
    };

    # 2
    # Manually set to 400
    specificArtifact = base.deployment.priority 400 (base.deployment.mkDeployment rec {
      name = "specific-artifact";
      deployPhase = ''
        echo "Deploying ${name}.."
      '';
    });

    # 4
    # This one will get a very low priority.
    lastArtifact = base.deployment.last (base.deployment.mkDeployment rec {
      name = "last-artifact";
      deployPhase = ''
        echo "Deploying ${name}.."
      '';
    });

    # 1
    # Will set the priority to 1.
    firstArtifact = base.deployment.first (base.deployment.mkDeployment rec {
      name = "first-artifact";

      deployPhase = ''
        echo "Deploying ${name}.."
      '';
    });
  };
}
