{ base, pkgs, mkDeployment }:
let
  deployer = pkgs.callPackage ./deployer.nix { inherit base; };
in
attrs@{ terraformPackage, preDeploy ? "", postDeploy ? "", shellInputs ? [ ], inputs ? [ ], ... }:
mkDeployment (attrs // {
  name = "deploy-terraform-${terraformPackage.name}";
  deployPhase = "exec ${deployer.package}/bin/terraform-deploy --source ${terraformPackage}/src $@";
  inherit preDeploy postDeploy shellInputs inputs;
})
