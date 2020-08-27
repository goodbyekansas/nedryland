{ base, pkgs }:
{
  mkTerraformComponent = attrs@{ name, src, buildInputs ? [ ], shellHook ? "", disableApplyInShell ? true, ... }:
    base.mkComponent rec {
      inherit name;
      package = pkgs.stdenv.mkDerivation (attrs // {
        inherit name;
        src = builtins.path {
          inherit name;
          path = src;
        };
        buildInputs = [ pkgs.terraform_0_13 ] ++ buildInputs;


        configurePhase = ''
          terraform init
        '';

        checkPhase = ''
          terraform fmt -recursive -check -diff
          terraform validate
        '';

        buildPhase = ''
          terraform plan -no-color > plan
        '';

        installPhase = ''
          mkdir $out
          cp plan $out/plan

          # output date
          date +%s > $out/plan-generated-at
        '';

        shellHook = ''
          ${if disableApplyInShell then ''
          terraform()
          {
          subcommand="$1"
          if [ $# -gt 0 ] && [ "$subcommand" == "apply" ]; then
          echo "Local `apply` has been disabled, which probably means that application of Terraform config is done centrally"
          else
          command terraform "$@"
          fi
          }
          '' else ""}
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
