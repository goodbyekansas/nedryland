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
    , variables ? { }
    , subComponents ? { }
    , ...
    }:
    let
      attrs = (builtins.removeAttrs attrs' [ "variables" "srcExclude" "subComponents" ]);
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
        buildInputs = [ pkgs."${versions.terraform}" ] ++ buildInputs;

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
        shellHook = ''
          terraform()
          {
            ${preTerraformHook}
            subcommand="$1"
            ${if disableApplyInShell then ''
            if [ $# -gt 0 ] && [ "$subcommand" == "apply" ]; then
              echo "Local 'apply' has been disabled, which probably means that application of Terraform config is done centrally"
              return 1
            else
              command terraform "$@"
              return $?
            fi
          '' else ''
            command terraform "$@"
            return $?
          ''}
            ${postTerraformHook}
          }

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
