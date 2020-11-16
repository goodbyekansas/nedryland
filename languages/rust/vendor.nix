pkgs: rust: { src, name, buildInputs, propagatedBuildInputs }:
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
    inherit src buildInputs propagatedBuildInputs;

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];
    nativeBuildInputs = with pkgs; [ git cacert rust internalSetupHook ];

    buildPhase = ''
      export CARGO_HOME=$PWD

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

        substitute ${./cargo-local.config.toml} $out/cargo.config.toml \
          --subst-var-by vendorDir $out/vendored

        mkdir -p "$out/nix-support"
        substituteAll "$setupHook" "$out/nix-support/setup-hook"
      fi
    '';

    impureEnvVars = pkgs.stdenv.lib.fetchers.proxyImpureEnvVars;
    setupHook = ./setupHook.sh;
  };

  # a derivation that checks that Cargo.lock is up to date
  # and generates an up-to-date one if it is not
  upToDateCargoLock = pkgs.stdenv.mkDerivation {
    name = "${name}-Cargo.lock";
    inherit src;

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    nativeBuildInputs = with pkgs; [ git cacert rust coreutils internal ];

    preBuild = ''
      if declare -f createCargoConfig > /dev/null; then
        createCargoConfig
      fi
    '';

    buildPhase = ''
      runHook preBuild
      export CARGO_HOME=$PWD

      cp Cargo.lock Cargo.lock.orig

      # this will contact crates.io to
      # check if the lock file is up to date
      # w.r.t. what is specified in the manifest (Cargo.toml)
      # We also run all commands with -q because the output
      # from a successful run is not all that helpful and
      # error output will still be printed
      if cargo update -q --locked; then
        echo "🔏 👍 Cargo.lock is up to date"
      else
        echo "🔏 🗓 Cargo.lock is out of date, generating a new one..."
        cargo update -q

        echo "An up-to-date Cargo.lock for \"${name}\" has been generated at $out"
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
    inherit src upToDateCargoLock;

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    nativeBuildInputs = with pkgs; [ git cacert rust internal ];

    preBuild = ''
      if declare -f createCargoConfig > /dev/null; then
        createCargoConfig
      fi
    '';

    buildPhase = ''
      runHook preBuild
      export CARGO_HOME=$PWD

      # check to see if Cargo.lock is up to date
      # the reason we do not fail the above derivation
      # if it isn't is to be able to provide the user
      # with an up-to-date Cargo.lock that they can
      # use
      if ! cmp Cargo.lock $upToDateCargoLock; then
        echo "❌ 💔 Cargo.lock is not up to date for \"${name}\"! You can use the one at $upToDateCargoLock"
        exit 1
      fi

      # We need to set this so that
      # cargo vendor will generate timestamps
      # that corresponds to those that will be in the
      # nix store (unix epoch 1). Otherwise the generated
      # checksums will change and cargo will not be able
      # to use the vendored packages
      export SOURCE_DATE_EPOCH=1

      echo "🌍 vendoring dependencies from crates.io..."

      # we cannot really run with --locked here because
      # that would require the internal dependencies to be
      # part of Cargo.toml. However, the validity of the lockfile
      # will still be guaranteed by the dependency on the upToDateCargoLock
      # derivation
      cargo vendor -q --versioned-dirs --respect-source-config vendored

      echo "🌍 dependencies from crates.io vendored!"
      runHook postBuild
    '';

    installPhase = ''
      mkdir $out

      cp -r vendored $out

      substitute ${./cargo.config.toml} $out/cargo.config.toml \
        --subst-var-by vendorDir $out/vendored

      mkdir -p "$out/nix-support"
      substituteAll "$setupHook" "$out/nix-support/setup-hook"
    '';

    setupHook = ./setupHook.sh;

    impureEnvVars = pkgs.stdenv.lib.fetchers.proxyImpureEnvVars;
  };
in
{ inherit internal external; }
