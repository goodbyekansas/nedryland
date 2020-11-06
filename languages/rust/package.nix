pkgs: base: attrs@{ name
            , src
            , extensions ? [ ]
            , targets ? [ ]
            , defaultTarget ? ""
            , useNightly ? ""
            , vendorDependencies ? true
            , extraChecks ? ""
            , buildFeatures ? [ ]
            , testFeatures ? [ ]
            , shellInputs ? [ ]
            , shellHook ? ""
            , warningsAsErrors ? true
            , ...
            }:
let
  # this controls the version of rust to use
  rust = (
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
        cargo run
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
              && !(!vendorDependencies && type == "regular" && baseNameOf path == "Cargo.lock")
          );
      }) else src;

  vendor = import ./vendor.nix pkgs rust {
    inherit name;
    src = invariantSource;
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

    rustWithSrc = (rust.override {
      extensions = [ "rust-src" ] ++ extensions;
    });
    inherit rust;

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
in
pkgs.stdenv.mkDerivation (
  safeAttrs // {
    inherit name;
    src = invariantSource;

    nativeBuildInputs = with pkgs; [
      cacert
      rust
    ] ++ attrs.nativeBuildInputs or [ ]
    ++ (pkgs.lib.lists.optionals (defaultTarget == "wasm32-wasi") [ pkgs.wasmer-with-run ])
    ++ [ vendor.internal ]
    ++ pkgs.lib.optional vendorDependencies vendor.external;

    buildInputs = attrs.buildInputs or [ ];
    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];

    shellInputs = shellInputs ++ [ rustSrcNoSymlinks ];

    configurePhase = attrs.configurePhase or ''
      runHook preConfigure
      export CARGO_HOME=$PWD
      if declare -f createCargoConfig > /dev/null; then
        createCargoConfig
      fi
      runHook postConfigure
    '';

    buildPhase = attrs.buildPhase or ''
      runHook preBuild
      cargo build --frozen --release ${getFeatures buildFeatures}
      runHook postBuild
    '';

    checkPhase = attrs.checkPhase or ''
      cargo fmt -- --check
      cargo test --frozen ${getFeatures testFeatures}
      cargo clippy --frozen ${getFeatures testFeatures}
      ${extraChecks}
    '';

    installPhase = attrs.installPhase or ''
      mkdir -p $out
    '';

    shellHook = ''
      export RUST_SRC_PATH=${rustSrcNoSymlinks}
      if declare -f createCargoConfig > /dev/null; then
        createCargoConfig
      fi
      ${cargoAlias}
      ${commands}
      ${shellHook}
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
  )
)
