{ writeScriptBin
, openssh
, wineWowPackages
, bash
, stdenv
, lib
, makeSetupHook
, writeTextFile
}:
makeSetupHook
{
  name = "windows-runner-setup-hook";
  substitutions = {
    runner =
      writeScriptBin "windows-runner" ''
        #! ${bash}/bin/bash
        set -e

        if [ -n "$NEDRYLAND_WINDOWS_HOST" ]; then
            hostname="localhost"
            username="User"
            IFS='@' read user host <<< "$NEDRYLAND_WINDOWS_HOST"
            if [ -n "$host" ]; then
              hostname="$host"
              username="$user"
            else
              hostname="$user"
            fi

            port=""
            IFS=':' read host p <<< "$hostname"
            if [ -n "$p" ]; then
              hostname="$host"
              port="$p"
            fi

            if [ -n "$port" ]; then
               sshFlags+=("-p $port")
            fi
            sshFlags=("-o StrictHostKeyChecking=no" "-o BatchMode=yes" "-o UserKnownHostsFile=/dev/null" "-F ${openssh}/etc/ssh/ssh_config")
            echo -n "Waiting for ssh to come up..."
            until $(${openssh}/bin/ssh -q -o ConnectTimeout=1 ''${sshFlags[*]} "$username"@"$hostname" "if not exist "rust" mkdir rust && exit"); do
              echo -n "."
              sleep 4
            done

            executable=$(basename "$1")
            echo "ssh is up, running!"
            ${openssh}/bin/scp ''${sshFlags[*]/-p/-P} "$1" "$username"@"$hostname":rust/$executable
            shift
            ${openssh}/bin/ssh -t ''${sshFlags[*]} "$username"@"$hostname" ".\\rust\\$executable" "$@"
        else if [ -n "WSL_DISTRO_NAME" ]; then
          "$@"
        else
          echo "Please set NEDRYLAND_WINDOWS_HOST to a Windows host where you have SSH access."
          exit 1
        fi
      '';

    postShell = writeTextFile {
      name = "post-shell";
      executable = true;
      text = ''
        nedrylandVmInfo() {
          echo "🏘 Set NEDRYLAND_WINDOWS_HOST to a hostname of a Windows machine"
          echo "  where you have SSH access (without password)."
          echo "  cargo run/test will use this host to run/test the code."
          echo "  If you need a VM to do this you may use https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/"
        }

        ${lib.optionalString (stdenv.buildPlatform.isLinux && builtins.getEnv "WSL_DISTRO_NAME" == "") ''
          cargoWine() {
            cacheFolder=$HOME/.cache/nedryland/
            mkdir -p "$cacheFolder/.wine"
            cacheFolder="$cacheFolder" CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER="${writeScriptBin
              "wine-runner" ''
                WINEPREFIX=$cacheFolder/.wine WINEDEBUG=fixme-all,warn WINEDLLOVERRIDES='mscoree,mshtml=' ${wineWowPackages.stable}/bin/wine64 "$1"
              ''}/bin/wine-runner" cargo "$@"
          }
        ''}
      '';
    };
  };
}
  (builtins.toFile "windows-runner-hook" ''
    export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER=@runner@/bin/windows-runner
    postShell="''${postShell:-} source @postShell@; nedrylandVmInfo"
  '')
