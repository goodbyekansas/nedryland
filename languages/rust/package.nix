{ pkgs
, base
, stdenv
, buildPackages
, rust # use this for toRustTarget
}:

attrs@{ name
, src
, extensions ? [ ]
, targets ? [ ]
, defaultTarget ? ""
, useNightly ? ""
, extraChecks ? ""
, buildFeatures ? [ ]
, testFeatures ? [ ]
, shellInputs ? [ ]
, shellHook ? ""
, warningsAsErrors ? true
, filterCargoLock ? false
, ...
}:
let
  # this controls the version of rust to use
  mozillaRust = (
    if useNightly != "" then
      (
        pkgs.rustChannelOf {
          date = useNightly;
          channel = "nightly";
        }
      ).rust.override
        {
          inherit targets extensions;
        }
    else
      (pkgs.rustChannelOf {
        channel = "1.47.0";
      }).rust.override {
        inherit targets extensions;
      }
  );

  commands = ''
    test() {
        eval "$checkPhase"
    }

    build() {
        eval "$buildPhase"
    }

    run() {
        cargo run "$@"
    }
  '';

  invariantSource =
    if !(pkgs.lib.isStorePath src) then
      (builtins.path {
        path = src;
        inherit name;
        filter =
          (
            path: type: !(type == "directory" && baseNameOf path == "target")
              && !(type == "directory" && baseNameOf path == ".cargo")
              && !(filterCargoLock && type == "regular" && baseNameOf path == "Cargo.lock")
          );
      }) else src;

  vendor = import ./vendor.nix pkgs mozillaRust {
    inherit name;
    buildInputs = attrs.buildInputs or [ ];
    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];
  };

  getFeatures = features:
    if (builtins.length features) == 0 then
      ""
    else
      ''--features "${(builtins.concatStringsSep " " features)}"'';


  # rust-analyzer cannot handle symlinks
  # so we need to create a derivation with the
  # correct rust source without symlinks
  rustSrcNoSymlinks = pkgs.stdenv.mkDerivation {
    name = "rust-src-no-symlinks";

    rustWithSrc = (mozillaRust.override {
      extensions = [ "rust-src" ] ++ extensions;
    });
    rust = mozillaRust;

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir -p $out
      cp -r -L $rustWithSrc/lib/rustlib/src/rust/library/. $out/
    '';
  };

  cargoAlias = ''
    cargo()
    {
    subcommand="$1"
    if [ $# -gt 0 ] && ([ "$subcommand" == "test" ] || [ "$subcommand" == "clippy" ]) ; then
      shift
      command cargo "$subcommand" ${getFeatures testFeatures} "$@"
    elif [ $# -gt 0 ] && ([ "$subcommand" == "build" ] || [ "$subcommand" == "run" ]) ; then
      shift
      command cargo "$subcommand" ${getFeatures buildFeatures} "$@"
    else
      command cargo "$@"
    fi
    }
  '';

  safeAttrs = builtins.removeAttrs attrs [ "extraChecks" "testFeatures" "buildFeatures" ];

  # cross compiling
  ccForBuild = "${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}cc";
  cxxForBuild = "${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}c++";
  ccForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc";
  cxxForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}c++";

  hostTriple = builtins.replaceStrings [ "-" ] [ "_" ] (rust.toRustTarget stdenv.hostPlatform);
  buildTriple = builtins.replaceStrings [ "-" ] [ "_" ] (rust.toRustTarget stdenv.buildPlatform);

in
stdenv.mkDerivation (
  safeAttrs // {
    inherit name;
    strictDeps = true;
    disallowedReferences = [ vendor ];
    src = invariantSource;

    nativeBuildInputs = with pkgs; [
      cacert
      mozillaRust
      removeReferencesTo
    ] ++ attrs.nativeBuildInputs or [ ]
    ++ (pkgs.lib.lists.optionals (defaultTarget == "wasm32-wasi") [ pkgs.wasmer-with-run ])
    ++ [ vendor ];

    buildInputs = attrs.buildInputs or [ ];
    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];

    shellInputs = shellInputs ++ [ rustSrcNoSymlinks ];

    configurePhase = attrs.configurePhase or ''
      runHook preConfigure
      export CARGO_HOME=$PWD
      runHook postConfigure
    '';

    buildPhase = attrs.buildPhase or ''
      runHook preBuild
      cargo build --release ${getFeatures buildFeatures}
      runHook postBuild
    '';

    checkPhase = attrs.checkPhase or ''
      cargo fmt -- --check
      cargo test ${getFeatures testFeatures}
      cargo clippy ${getFeatures testFeatures}
      ${extraChecks}
    '';

    installPhase = attrs.installPhase or ''
      mkdir -p $out
    '';

    preFixup = ''
      # The binary we built will be full of paths pointing to the nix store.
      # Nix thinks it is doing us a favour by automatically adding dependencies
      # by finding store paths in the binary. We strip these store paths so
      # Nix won't find them.
      find $out -type f -exec remove-references-to -t ${vendor} '{}' +
      find $out -type f -exec remove-references-to -t ${mozillaRust} '{}' +
    '';

    shellHook = ''
      runHook preShell
      export RUST_SRC_PATH=${rustSrcNoSymlinks}
      ${cargoAlias}
      ${commands}
      ${shellHook}
      runHook postShell
    '';

  } // (
    if defaultTarget != "" then {
      CARGO_BUILD_TARGET = defaultTarget;
    } else { }
  ) // (
    if defaultTarget == "wasm32-wasi" then {
      # run the tests through virtual vm, create a temp directory and map it to the vm
      CARGO_TARGET_WASM32_WASI_RUNNER = pkgs.writeTextFile {
        name = "runner.sh";
        executable = true;
        text = ''
          temp_dir=$(mktemp -d)
          wasmer run --env=RUST_TEST_NOCAPTURE=1 --mapdir=:$temp_dir "$@"
          exit_code=$?
          rm -rf $temp_dir
          exit $exit_code
        '';
      };
    } else { }
  ) // (
    if warningsAsErrors then {
      RUSTFLAGS = "-D warnings";
    } else { }
  ) // (
    if hostTriple != buildTriple then {
      # cross-things
      "CARGO_TARGET_${stdenv.lib.toUpper hostTriple}_LINKER" = "${ccForHost}";
      "CC_${stdenv.lib.toUpper hostTriple}" = "${ccForHost}";
      "CXX_${stdenv.lib.toUpper hostTriple}" = "${cxxForHost}";

      "CARGO_TARGET_${stdenv.lib.toUpper buildTriple}_LINKER" = "${ccForBuild}";
      "CC_${stdenv.lib.toUpper buildTriple}" = "${ccForBuild}";
      "CXX_${stdenv.lib.toUpper buildTriple}" = "${cxxForBuild}";
    } else { }
  )
)
