pkgs: rust: { src, vendorDependencies, cargoLockHash, externalDependenciesHash, name, buildInputs, propagatedBuildInputs }:
let
  internalSetupHook = pkgs.makeSetupHook
    {
      name = "internal-deps-hook";
    }
    ./internalDepsSetupHook.sh;

  # derivation that creates a fake vendor dir
  # with our internal nix dependencies
  internal = pkgs.stdenv.mkDerivation {
    name = "${name}-internal-deps";
    inherit buildInputs propagatedBuildInputs;

    phases = [ "buildPhase" "installPhase" ];
    nativeBuildInputs = with pkgs; [ git cacert rust internalSetupHook ];

    buildPhase = ''
      if [ -n "''${rustDependencies}" ]; then
        echo "🏡 vendoring internal dependencies..."

        mkdir -p vendored

        # symlink in all deps
        for dep in $rustDependencies; do
          ln -sf "$dep" ./vendored/
        done

        echo "🏡 internal dependencies vendored!"
      fi
    '';

    installPhase = ''
      mkdir $out

      if [ -d vendored ]; then
        cp -r vendored $out
      fi
    '';
  };

  # a derivation that checks that Cargo.lock is up to date
  # and generates an up-to-date one if it is not
  upToDateCargoLock = pkgs.stdenv.mkDerivation {
    name = "${name}-Cargo.lock";
    inherit src internal;

    outputHash = cargoLockHash;
    outputHashAlgo = "sha256";

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    nativeBuildInputs = with pkgs; [ git cacert rust ];

    preBuild = ''
      if [ -d $internal/vendored ]; then
         substitute ${./cargo-internal.config.toml} config.toml \
         --subst-var-by vendorDir $internal/vendored
      fi
    '';

    buildPhase = ''
      runHook preBuild
      export CARGO_HOME=$PWD

      # this will contact crates.io to
      # check if the lock file is up to date
      # w.r.t. what is specified in the manifest (Cargo.toml)
      # We also run all commands with -q because the output
      # from a successful run is not all that helpful and
      # error output will still be printed
      echo "🔐 🧐 Checking if Cargo.lock is up to date..."
      if cargo update -q --locked; then
        echo "🔏 👍 Cargo.lock is up to date"
      else
        echo -e "🔓 🗓 \e[31mERROR: Cargo.lock is out of date, generating a new one...\e[0m"
        cargo update -q
        echo "An up-to-date Cargo.lock for \"${name}\" has been generated at $out"

        echo "Please replace your old lock file with the following command."
        echo "\"cp $out <path to ${name}/Cargo.lock>\""
      fi
      runHook postBuild
    '';

    installPhase = ''
      cp Cargo.lock $out
    '';

    impureEnvVars = pkgs.stdenv.lib.fetchers.proxyImpureEnvVars;
  };

  # a derivation that generates a "vendor" dir with
  # all internal and crates.io dependencies
  external = pkgs.stdenv.mkDerivation {
    name = "${name}-external-deps";
    inherit src upToDateCargoLock internal;

    outputHash = externalDependenciesHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    nativeBuildInputs = with pkgs; [ git cacert rust nix coreutils ];

    preBuild = ''
      if [ -d $internal/vendored ]; then
         substitute ${./cargo-internal.config.toml} config.toml \
         --subst-var-by vendorDir $internal/vendored
      fi
    '';

    buildPhase = ''
      runHook preBuild

      export CARGO_HOME=$PWD

      cp Cargo.lock Cargo.lock.orig

      # We need to set this so that
      # cargo vendor will generate timestamps
      # that corresponds to those that will be in the
      # nix store (unix epoch 1). Otherwise the generated
      # checksums will change and cargo will not be able
      # to use the vendored packages
      export SOURCE_DATE_EPOCH=1

      echo "🌍 vendoring dependencies from crates.io..."
      cargo vendor -q --versioned-dirs --locked --respect-source-config vendored
      echo "🌍 dependencies from crates.io vendored!"

      runHook postBuild
    '';

    installPhase = ''
      mkdir $out

      cp -r vendored $out

      newSha256=$(nix hash-path $out --type sha256)
      oldSha256=$(nix to-base64 $outputHash --type sha256)
      formattedNewSha256=$(nix to-base64 $newSha256 --type sha256)
      if [ "$formattedNewSha256" != "$oldSha256" ]; then
         echo -e "❌🔮 \e[31mHash mismatch for external dependencies!\e[0m"
         echo -e "     \e[1mProvided Hash:\e[0m \"$oldSha256\""
         echo -e "     \e[1mExternal Dependencies Hash:\e[0m \"$formattedNewSha256\""
         echo -e "     \e[1mMake sure you are providing the correct hash for \"${name}\":\e[0m externalDependenciesHash = \"$newSha256\";"

         if ! cmp -s Cargo.lock Cargo.lock.orig; then
           echo "     This might be since there is a mismatch in Cargo.lock (i.e. vendoring created a new lock file)"
         else
           echo "     However, the cargo lock files are identical!"
         fi

         exit 1
      fi
    '';
    impureEnvVars = pkgs.stdenv.lib.fetchers.proxyImpureEnvVars;
  };

in
pkgs.stdenv.mkDerivation ({
  name = "${name}-vendored-dependencies";
  inherit internal;
  phases = [ "buildPhase" "installPhase" ];

  buildPhase = ''
    if [ -d $internal/vendored ]; then
       substitute ${./cargo-internal.config.toml} internal-cargo.config.toml \
       --subst-var-by vendorDir $internal/vendored

       cat internal-cargo.config.toml >> cargo.config.toml
    fi

    if [ -n "''${external-}" ] && [ -d $external/vendored ]; then
       substitute ${./cargo-external.config.toml} external-cargo.config.toml \
       --subst-var-by vendorDir $external/vendored

       cat external-cargo.config.toml >> cargo.config.toml
    fi
  '';

  installPhase = ''
    mkdir -p $out
    if [ -f cargo.config.toml ]; then
       cp cargo.config.toml $out
       mkdir -p "$out/nix-support"
       substituteAll "$setupHook" "$out/nix-support/setup-hook"
    fi
  '';
  setupHook = ./setupHook.sh;
} // (if vendorDependencies then { inherit external; } else { }))
