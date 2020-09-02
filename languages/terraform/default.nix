{ base, pkgs }:
{
  mkTerraformComponent =
    attrs@{ name
    , src
    , buildInputs ? [ ]
    , shellHook ? ""
    , disableApplyInShell ? true
    , preTerraformHook ? ""
    , postTerraformHook ? ""
    , variables ? { }
    , ...
    }:
    base.mkComponent rec {
      inherit name;
      package = pkgs.stdenv.mkDerivation ((builtins.removeAttrs attrs [ "variables" ]) // {
        inherit name;
        src = builtins.path {
          inherit name;
          path = src;
        };
        buildInputs = [ pkgs.terraform_0_13 ] ++ buildInputs;
        variablesFile = (builtins.toJSON variables);
        passAsFile = [ "variablesFile" ];

        configurePhase = ''
          terraform init -lock-timeout=300s
          cp "$variablesFilePath" tfvars.json
        '';

        checkPhase = ''
          terraform fmt -recursive -check -diff
          terraform validate
        '';

        buildPhase = ''
          terraform plan -var-file="tfvars.json" -lock-timeout=300s -no-color > plan
        '';

        installPhase = ''
          mkdir $out
          cp plan $out/plan
          cp $variablesFilePath $out/vars.json

          # output date
          date +%s > $out/plan-generated-at
        '';

        shellHook = ''
          cp "$variablesFilePath" /tmp/tfvars.json

          terraform_with_args()
          {
            subcommand="$1"
            if [ "$subcommand" == "apply" ] || [ "$subcommand" == "plan" ]; then
               command terraform "$@" -var-file=/tmp/tfvars.json
               return $?
            else
               command terraform "$@"
               return $?
            fi
          }

          terraform()
          {
            ${preTerraformHook}
            subcommand="$1"
            ${if disableApplyInShell then ''
            if [ $# -gt 0 ] && [ "$subcommand" == "apply" ]; then
              echo "Local 'apply' has been disabled, which probably means that application of Terraform config is done centrally"
              return 1
            else
              terraform_with_args "$@"
              return $?
            fi
          '' else ''
            terraform_with_args "$@"
            return $?
          ''}
            ${postTerraformHook}
          }
          ${shellHook}
        '';
      });

      deployment = {
        terraform = base.deployment.terraformComponent {
          inherit package;
        };
      };
    };
}
