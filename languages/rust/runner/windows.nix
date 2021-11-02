{ buildPlatform
, hostPlatform
, attrs
, lib
, writeScriptBin
, openssh
, wineWowPackages
, bash
}:
if lib.inNixShell && hostPlatform == "x86_64-pc-windows-gnu" && builtins.getEnv "WSL_DISTRO_NAME" == "" then
  {
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = "${writeScriptBin "windows-runner" ''
      #! ${bash}/bin/bash
      set -e
      echo -n "Waiting for ssh to come up..."
      sshFlags=("-o StrictHostKeyChecking=no" "-o BatchMode=yes" "-o UserKnownHostsFile=/dev/null" "-F ${openssh}/etc/ssh/ssh_config")

      hostname="localhost"
      username="User"
      if [ -n "$NEDRYLAND_WINDOWS_HOST" ]; then
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
      else
        echo "Please set NEDRYLAND_WINDOWS_HOST to a Windows host where you have SSH access."
        exit 1
      fi

      until $(${openssh}/bin/ssh -q -o ConnectTimeout=1 ''${sshFlags[*]} "$username"@"$hostname" "if not exist "rust" mkdir rust && exit"); do
        echo -n "."
        sleep 4
      done

      executable=$(basename "$1")
      echo "ssh is up, running!"
      ${openssh}/bin/scp ''${sshFlags[*]/-p/-P} "$1" "$username"@"$hostname":rust/$executable
      shift
      ${openssh}/bin/ssh -t ''${sshFlags[*]} "$username"@"$hostname" ".\\rust\\$executable" "$@"
    ''}/bin/windows-runner";

    postShell = ''
      ${attrs.postShell or ""}

      ${if buildPlatform.isLinux then
        ''
        cargoWine() {
          cacheFolder=$HOME/.cache/nedryland/
          mkdir -p "$cacheFolder/.wine"

          cacheFolder="$cacheFolder" CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER="${writeScriptBin "wine-runner" ''
            WINEPREFIX=$cacheFolder/.wine WINEDEBUG=fixme-all,warn WINEDLLOVERRIDES='mscoree,mshtml=' ${wineWowPackages.stable}/bin/wine64 "$1"
          ''}/bin/wine-runner" cargo "$@"
        }''
        else
          ""
       }

      echo "🏘 Set NEDRYLAND_WINDOWS_HOST to a hostname of a Windows machine"
      echo "  where you have SSH access (without password)."
      echo "  cargo run/test will use this host to run/test the code."
      echo "  If you need a VM to do this you may use https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/"
    '';
  }
else { }
