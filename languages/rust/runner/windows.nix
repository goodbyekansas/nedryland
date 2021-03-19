{ buildPlatform
, hostPlatform
, attrs
, fetchzip
, qemu
, lib
, writeScriptBin
, curl
, unzip
, runCommand
, stdenv
, openssh
, wineWowPackages
}:
let
  imageVersion = "2102";
  determineCacheFolder = ''
    cacheFolder=''${HOME}/.cache/nedryland
    if [ -w /var/cache/nedryland ]; then
      cacheFolder=/var/cache/nedryland
    fi
  '';
in
# do not want a 20 Gb download when building
if lib.inNixShell && hostPlatform == "x86_64-pc-windows-gnu" && builtins.getEnv "WSL_DISTRO_NAME" == "" then
  {
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = "${writeScriptBin "windows-runner" ''
      set -e
      ${determineCacheFolder}
      echo -n "Waiting for ssh to come up..."
      sshFlags=("-o StrictHostKeyChecking=no" "-o UserKnownHostsFile=/dev/null" "-i $cacheFolder/windows-vm-ssh-key" "-p 5000" "-F ${openssh}/etc/ssh/ssh_config")
      until $(${openssh}/bin/ssh -q -o ConnectTimeout=1 ''${sshFlags[*]} User@localhost "if not exist "rust" mkdir rust && exit"); do
        echo -n "."
        sleep 4
      done

      executable=$(basename "$1")
      echo "ssh is up, running!"
      ${openssh}/bin/scp ''${sshFlags[*]/-p/-P} "$1" User@localhost:rust/$executable
      shift
      ${openssh}/bin/ssh -t ''${sshFlags[*]} User@localhost ".\\rust\\$executable" "$@"
    ''}/bin/windows-runner";

    postShell = ''
      ${attrs.postShell or ""}

      ${if buildPlatform.isLinux then
        ''
        cargoWine() {
          ${determineCacheFolder}
          mkdir -p $cacheFolder/.wine

          cacheFolder=$cacheFolder CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER="${writeScriptBin "wine-runner" ''
            WINEPREFIX=$cacheFolder/.wine WINEDEBUG=fixme-all,warn WINEDLLOVERRIDES='mscoree,mshtml=' ${wineWowPackages.stable}/bin/wine64 "$1"
          ''}/bin/wine-runner" cargo "$@"
        }''
        else
          ""
       }

      runWindowsVm() {
        ${determineCacheFolder}
        imagePath="$cacheFolder/windows-vm-${imageVersion}.qcow2";
        imageTmpFs="$cacheFolder/windows-tmp-fs";
        if [ ! -f $imagePath ]; then
          echo "🪟 Will download a Windows image to run on."
          echo "🐌 This will most likely take a while."
          echo "☕ Do you want to proceed with coffee break?"
          read -p "y/n " -n 1 -r
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
             return 1
          fi
          echo
          echo "🧹 Cleaning up old image files."
          rm -f $cacheFolder/windows-vm*.qcow2

          echo "💾 Downloading Windows VM Image..."
          mkdir -p $cacheFolder
          ${curl}/bin/curl https://download.microsoft.com/download/1/9/c/19cd64da-7dee-4ac6-9471-9eb1b4aab474/WinDev2102Eval.VMware.zip \
            -o $cacheFolder/windows-vm.zip

          echo "⛽ Unpacking Windows VM Image..."
          ${unzip}/bin/unzip $cacheFolder/windows-vm.zip -d $cacheFolder/windows-vm.tmp
          rm -f $cacheFolder/windows-vm.zip

          echo "🐮 🤠 Converting Windows VM Image to qcow2..."
          ${qemu}/bin/qemu-img convert $cacheFolder/windows-vm.tmp/WinDev${imageVersion}Eval-disk1.vmdk \
            -o cluster_size=2M,preallocation=metadata,lazy_refcounts=on -O qcow2 $imagePath
          rm -rf $cacheFolder/windows-vm.tmp
        fi

        echo "Generating SSH key for VM..."
        install_scripts_dir=$cacheFolder/install_scripts
        rm -f $cacheFolder/windows-vm-ssh-key $cacheFolder/windows-vm-ssh-key.pub
        ${openssh}/bin/ssh-keygen -f $cacheFolder/windows-vm-ssh-key -t ed25519 -q -N ""
        (
          rm -rf $install_scripts_dir
          mkdir -p $install_scripts_dir
          source $stdenv/setup
          substitute ${./install-openssh.ps1} $install_scripts_dir/install-openssh.ps1 --subst-var-by pubSshKey "$(cat $cacheFolder/windows-vm-ssh-key.pub)"

          cp ${./run_me.bat} $install_scripts_dir/run_me.bat
        )

        echo "👟 Running Windows VM..."
        mkdir -p $imageTmpFs
        TMPDIR=$imageTmpFs ${qemu}/bin/qemu-system-x86_64 \
          -drive format=qcow2,file=$imagePath,cache.direct=on,cache=writeback,aio=native \
          -fda fat:floppy:$install_scripts_dir \
          -name "rust-windows-testvm" \
          -m 4G \
          -smp cores=4,sockets=1 \
          -snapshot \
          -nic user,hostfwd=tcp::5000-:22 \
          ${if buildPlatform.isLinux then
              "-accel kvm -cpu host"
            else
              "-accel hvf -cpu host,-rdtscp"
           } &

           echo "Unfortunately we haven't figured out a way to enable ssh on the vm."
           echo -e "\033[1mYou will have to do it manually.\033[0m"
           echo "However, we have prepared a floppy for you. "
           echo "Run A:\run_me.bat"
           echo "P.S. It is totally not a virus D.S."
      }
      echo "🏘 To download and run a Windows VM, run: runWindowsVm."
      echo "cargo run/test will try to use this VM to run the code"
    '';
  }
else { }
