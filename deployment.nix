{ pkgs, base }:
let
  # Function to create a deployment
  mkDeployment =
    attrs@ { name
    , deployPhase
    , inputs ? [ ]
    , shellInputs ? [ ]
    , deployShell ? true
    , preDeploy
    , postDeploy
    , ...
    }:
    let
      env = attrs // {
        buildInputs = inputs;
      };
      envVars = pkgs.writeTextFile {
        name = "${name}-env";
        text = builtins.foldl'
          (acc: curr: ''
            ${acc}
            declare -x ${curr}="${builtins.replaceStrings [ "$" "\"" ] [ "\\$" "\\\"" ] (builtins.toString (builtins.getAttr curr env))}"
          '')
          # These variables are needed for stdenvs setup
          ''
            declare -x out="/not-set"
            declare -x SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            declare -x noDumpEnvVars=1
          ''
          (builtins.attrNames attrs);
      };
      deploy = pkgs.writeTextFile {
        name = "${name}-deploy";
        text = ''
          #!${pkgs.bash}/bin/bash
          source ${envVars}
          source ${pkgs.stdenvNoCC}/setup

          ${preDeploy}
          ${deployPhase}
          ${postDeploy}
        '';
        executable = true;
        destination = "/bin/deploy";
      };
      shell = pkgs.writeTextFile {
        name = "${name}-deploy-shell";
        text = ''
          #!${pkgs.bash}/bin/bash
          source ${envVars}
          source ${pkgs.stdenvNoCC}/setup

          ${preDeploy}
          PS1="\n\e[1;32m[${name}]\e[0m ⛴  \e[1;32m> \e[0m" ${pkgs.bashInteractive}/bin/bash --norc
        '';
        executable = true;
        destination = "/bin/shell";
      };
    in
    pkgs.symlinkJoin { inherit name; paths = [ deploy ] ++ pkgs.lib.optional deployShell shell; };
in
{
  inherit mkDeployment;
  mkCombinedDeployment = name: deployments:
    if builtins.length (builtins.attrNames deployments) == 1 then
      builtins.head (builtins.attrValues deployments)
    else
      mkDeployment {
        inherit name;
        preDeploy = "";
        postDeploy = "";
        deployShell = false;
        deployPhase = builtins.foldl'
          (
            acc: curr: ''
              ${acc}
              echo "📡👽 Deploying ${curr}..."
              ${builtins.getAttr curr deployments}/bin/deploy 2>&1 | sed "s/^/ 🛸 ''${esc}[36m[${curr}]''${esc}[0m /"
            ''
          )
          ''
            #!${pkgs.bash}/bin/bash
            set -e
            esc=$(printf '\033')
          ''
          (builtins.attrNames deployments);
      };
  mkFileUploadDeployment = files: { };
  mkTerraformDeployment = import ./deployment/terraform/terraform.nix { inherit base pkgs mkDeployment; };
}
