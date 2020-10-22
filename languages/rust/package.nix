pkgs: base: attrs@{ name
            , src
            , buildInputs ? [ ]
            , extensions ? [ ]
            , targets ? [ ]
            , rustDependencies ? [ ]
            , defaultTarget ? ""
            , useNightly ? ""
            , filterLockFile ? false
            , extraChecks ? ""
            , buildFeatures ? [ ]
            , testFeatures ? [ ]
            , shellInputs ? [ ]
            , shellHook ? ""
            , ...
            }:
let
  rustPhase = ''
    if [ -z $IN_NIX_SHELL ]; then
      export CARGO_HOME=$PWD
    fi
  '';

  copyRustDeps = left: right: ''
    ${left}
    PACKAGE_PATH="nix-deps/${right.package.name}"
    FILE_NAME="nix-deps/${right.package.name}-copied-from"

    if [[ ! -d "$PACKAGE_PATH" || ! -f  "$FILE_NAME" || $(cat "$FILE_NAME") != ${right.package} ]]; then
      echo "📦💨 Copying ${right.package.name} to nix-deps."

      # copy package source
      if [ -d "$PACKAGE_PATH" ]; then
        chmod +w -R "$PACKAGE_PATH"
        rm -rf "$PACKAGE_PATH"
      fi
      cp -r ${right.package} "$PACKAGE_PATH"

      # write source location file
      if [ -f "$FILE_NAME" ]; then
        chmod +w "$FILE_NAME"
      fi
      echo "${right.package}" > "$FILE_NAME"
      chmod 0444 "$FILE_NAME"

      # patch up Cargo.toml
      echo "🐷 Patching $PACKAGE_PATH/Cargo.toml to fix transitive dependencies."
      chmod +w -R "$PACKAGE_PATH"
      sed -i -E 's/nix-deps/\.\./g' "$PACKAGE_PATH"/Cargo.toml
      chmod -w -R "$PACKAGE_PATH"

    else
      echo "🍄 Skipping copying ${right.package.name} since it's already up to date."
    fi
  '';

  collectRustDeps = attrs:
    if builtins.hasAttr "rustDependencies" attrs then
      attrs.rustDependencies ++ (builtins.map (dep: collectRustDeps dep) attrs.rustDependencies)
    else
      [ ];

  getFeatures = features:
    if (builtins.length features) == 0 then
      ""
    else
      ''--features "${(builtins.concatStringsSep " " features)}"'';

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

  safeAttrs = builtins.removeAttrs attrs [ "rustDependencies" "extraChecks" "testFeatures" "buildFeatures" ];
in
pkgs.stdenv.mkDerivation (
  safeAttrs // {
    inherit name;
    src =
      (builtins.path {
        path = src;
        inherit name;
        filter =
          (
            path: type: !(type == "directory" && baseNameOf path == "target")
            && !(type == "directory" && baseNameOf path == "nix-deps")
            && !(filterLockFile && type == "regular" && baseNameOf path == "Cargo.lock")
          );
      });

    nativeBuildInputs = with pkgs; [
      cacert
      rust
    ] ++ attrs.nativeBuildInputs or [ ] ++ buildInputs ++ (pkgs.lib.lists.optionals (defaultTarget == "wasm32-wasi") [ pkgs.wasmer-with-run ]);

    shellInputs = shellInputs ++ [ rustSrcNoSymlinks ];

    configurePhase = attrs.configurePhase or ''
      mkdir -p nix-deps

      ${builtins.foldl' copyRustDeps "" (
        pkgs.lib.lists.unique (pkgs.lib.lists.flatten (
            rustDependencies ++ (builtins.map (dep: (collectRustDeps dep)) rustDependencies)
            ))
        )
      }
      ${rustPhase}
    '';

    buildPhase = attrs.buildPhase or ''
      cargo build --release ${getFeatures buildFeatures}
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

    shellHook = ''
      eval "$configurePhase"
      export RUST_SRC_PATH=${rustSrcNoSymlinks}
      ${cargoAlias}
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
  )
)
