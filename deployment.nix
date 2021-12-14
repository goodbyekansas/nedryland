pkgs:
let
  # Function to create a deployment
  mkDeployment =
    attrs@ { name
    , deployPhase
    , inputs ? [ ]
    , deployShell ? true
    , preDeployPhase ? ""
    , postDeployPhase ? ""
    , ...
    }:
    let
      env = builtins.removeAttrs attrs [ "preDeployPhase" "deployPhase" "postDeployPhase" ] // {
        buildInputs = inputs;
      };
      envVars = pkgs.writeTextFile {
        name = "${name}-env";
        text = builtins.foldl'
          (acc: curr: ''
            ${acc}
            declare -x ${curr}="${builtins.replaceStrings [ "$" "\"" "\\" ] [ "\\$" "\\\"" "\\\\" ] (builtins.toString (builtins.getAttr curr env))}"
          '')
          # These variables are needed for stdenvs setup
          ''
            declare -x out="/deploy/should/not/generate/output"
            declare -x SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            declare -x noDumpEnvVars=1
          ''
          (builtins.attrNames env);
      };
      deploy = pkgs.writeTextFile {
        name = "${name}-deploy";
        text = ''
          #!${pkgs.bash}/bin/bash
          source ${envVars}
          source ${pkgs.stdenvNoCC}/setup

          keep=false
          while true; do
            case "$1" in
              -k | --keep-work-dir ) keep=true; shift ;;
              -- ) shift; break ;;
              * ) break ;;
            esac
          done

          workdir=$(mktemp -d --tmpdir ${name}-deploy-XXXXXXXX)
          echo "🏛️ Using temporary working directory $workdir"
          if [ "$keep" == false ]; then
            echo "🏛️ To keep the working directory run deploy with --keep-work-dir"
          fi
          pushd $workdir

          runHook preDeploy
          ${preDeployPhase}
          ${deployPhase}
          ${postDeployPhase}
          runHook postDeploy
          
          popd
          if [ "$keep" == false ]; then
            rm -rf $workdir
          fi
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

          runHook preDeployShell
          ${preDeployPhase}
          PS1="\n\e[1;32m[${name}]\e[0m ⛴  \e[1;32m> \e[0m" ${pkgs.bashInteractive}/bin/bash --norc
        '';
        executable = true;
        destination = "/bin/shell";
      };
    in
    pkgs.symlinkJoin {
      inherit name;
      paths = [ deploy ] ++ pkgs.lib.optional deployShell shell;
    };
in
base:
{
  inherit mkDeployment;

  first = deployment: deployment.overrideAttrs (_: {
    passthru = {
      priority = 1;
    };
  });

  last = deployment: deployment.overrideAttrs (_: {
    passthru = {
      priority = 999999;
    };
  });

  priority = priority: deployment: deployment.overrideAttrs (_: {
    passthru = {
      inherit priority;
    };
  });

  mkCombinedDeployment = name: deployments:
    if builtins.length (builtins.attrNames deployments) == 1 then
      builtins.head (builtins.attrValues deployments)
    else
      let
        sortedDeployments = builtins.map (value: value.name) (
          builtins.sort (first: second: builtins.lessThan first.priority second.priority)
            (
              pkgs.lib.mapAttrsToList
                (
                  name: value: { inherit name; priority = value.priority or 1000; }
                )
                deployments
            )
        );
      in
      (mkDeployment {
        inherit name;
        deployShell = false;
        deployPhase = builtins.foldl'
          (
            acc: curr: ''
              ${acc}
              echo "📡👽 Deploying ${curr}..."
              ${builtins.getAttr curr deployments}/bin/deploy "$@" 2>&1 | sed "s/^/ 🛸 ''${esc}[36m[${curr}]''${esc}[0m /"
            ''
          )
          ''
            #!${pkgs.bash}/bin/bash
            set -e
            esc=$(printf '\033')
          ''
          sortedDeployments;
      }).overrideAttrs (_: { passthru = { inherit sortedDeployments; }; });

  mkFileUploadDeployment = _: { };
  mkTerraformDeployment = import ./deployment/terraform/terraform.nix { inherit base pkgs mkDeployment; };
}
