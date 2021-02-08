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
    , preDeployPhase ? ""
    , postDeployPhase ? ""
    , deployShellInputs ? [ ]
    , variables ? { }
    , ...
    }:
    let
      safeAttrs = (builtins.removeAttrs attrs [ "variables" ]);
    in
    base.mkComponent rec {
      inherit name;
      package = pkgs.stdenv.mkDerivation (safeAttrs // {
        inherit name;
        src = builtins.path {
          inherit name;
          path = src;
          filter = (path: type: !(type == "directory" && baseNameOf path == ".terraform"));
        };
        buildInputs = [ pkgs.terraform_0_13 ] ++ buildInputs;

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
        terraform = pkgs.lib.makeOverridable base.deployment.mkTerraformDeployment (safeAttrs // {
          terraformPackage = package;
          inherit preDeployPhase postDeployPhase;
          shellInputs = deployShellInputs;
          inputs = package.buildInputs;
        });
      };
    };
}
