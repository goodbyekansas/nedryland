{ base, pkgs, versions }:
{
  mkTerraformComponent =
    attrs'@{ name
    , src
    , srcExclude ? [ ]
    , buildInputs ? [ ]
    , shellHook ? ""
    , disableApplyInShell ? true
    , preTerraformHook ? ""
    , postTerraformHook ? ""
    , preDeployPhase ? ""
    , postDeployPhase ? ""
    , deployShellInputs ? [ ]
    , subComponents ? { }
    , ...
    }:
    let
      attrs = (builtins.removeAttrs attrs' [ "variables" "srcExclude" "subComponents" "shellCommands" ]);
      terraformPkg = pkgs."${versions.terraform}";
    in
    base.mkComponent rec {
      inherit name subComponents;
      package = base.mkDerivation (attrs // {
        inherit name;
        src = if pkgs.lib.isStorePath src then src else
        builtins.path {
          inherit name;
          path = src;
          filter = (path: type:
            !(type == "directory" && baseNameOf path == ".terraform")
              && !(builtins.any (pred: pred path type) srcExclude)
          );
        };
        buildInputs = [ terraformPkg ] ++ buildInputs;

        checkPhase = ''
          terraform init -backend=false
          terraform fmt -recursive -check -diff
          terraform validate
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/src
          cp -r $src/. $out/src/
          
          runHook postInstall
        '';
        phases = [ "unpackPhase" "installPhase" "checkPhase" ];

        shellCommands = {
          build = {
            script = "eval $buildPhase";
            show = false;
          };
          terraform = {
            script = ''
              ${preTerraformHook}
              subcommand="$1"
              ${if disableApplyInShell then ''
                if [ $# -gt 0 ] && [ "$subcommand" == "apply" ]; then
                  echo "Local 'apply' has been disabled, which probably means that application of Terraform config is done centrally"
                  exit 1
                else
                  ${terraformPkg}/bin/terraform "$@"
                fi
              '' else ''
                ${terraformPkg}/bin/terraform "$@"
              ''}
              ${postTerraformHook}'';
            show = false;
          };
        } // attrs'.shellCommands or { };

        shellHook = ''
          ${if disableApplyInShell then ''echo "❕ Note that terraform apply is disabled in this shell."'' else ""}
          ${shellHook}
        '';
      });

      deployment = {
        terraform = pkgs.lib.makeOverridable base.deployment.mkTerraformDeployment (attrs // {
          terraformPackage = package;
          inherit preDeployPhase postDeployPhase;
          shellInputs = deployShellInputs;
          inputs = package.buildInputs;
        });
      };
      terraform = package;
    };
}
