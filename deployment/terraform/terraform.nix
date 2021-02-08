{ base, pkgs, mkDeployment }:
let
  deployer = pkgs.callPackage ./deployer.nix { inherit base; };
in
attrs@{ terraformPackage, preDeployPhase ? "", postDeployPhase ? "", shellInputs ? [ ], inputs ? [ ], ... }:
mkDeployment (attrs // {
  name = "deploy-terraform-${terraformPackage.name}";
  deployPhase = "command ${deployer.package}/bin/terraform-deploy --source ${terraformPackage}/src $@";
  inherit preDeployPhase postDeployPhase shellInputs inputs;
})
