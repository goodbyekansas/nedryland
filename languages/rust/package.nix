pkgs: base: { name
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
            }:
let
  rustPhase = ''
    if [ -z $IN_NIX_SHELL ]; then
      export RUSTC_WRAPPER=sccache

      home_cache="${builtins.getEnv "HOME"}/.cache/nedryland-rust/${name}"
      var_cache="/var/cache/nedryland-rust/${name}"
      tmp_cache="/tmp/cache/nedryland-rust/${name}"

      if [ -w "${builtins.getEnv "HOME"}/.cache" ]; then # Home folder (single user install)
           echo "Using rust cache directory \"$home_cache\""
           mkdir -p "$home_cache"
           export SCCACHE_DIR="$home_cache"
      elif [ -w "$(dirname "$var_cache")" ]; then
           echo "Using rust cache directory \"$var_cache\""

           if [ ! -d "$var_cache" ]; then
             echo "$var_cache" does not exist, creating...
             mkdir -p "$var_cache"
             chmod g+w "$var_cache"
           fi

           export SCCACHE_DIR="$var_cache"
      else
           echo "Using rust cache directory \"$tmp_cache\""
           echo "WARNING: Using fallback cache location.
           If you are running single user nix install check
           the permissions of your home folder. If you are
           running multi user nix install we use the
           location \"$var_cache\", please make sure that
           folder exists and is writable by the group \"$(id -gn)\""

           if [ ! -d "$tmp_cache" ]; then
             echo "$tmp_cache" does not exist, creating...
             mkdir -p "$tmp_cache"
             chmod g+w "$tmp_cache"
           fi

           export SCCACHE_DIR="$tmp_cache"
      fi
      export SCCACHE_SERVER_PORT=$(${pkgs.python}/bin/python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
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
  # TODO: might be beneficial for reproducible builds
  # to lock down the stable version of rust as well
  rust = (
    if useNightly != "" then
      (
        pkgs.rustChannelOf {
          date = useNightly;
          channel = "nightly";
        }
      ).rust.override {
        extensions = [ "rust-src" ] ++ extensions;
        inherit targets;
      }
    else
      pkgs.latest.rustChannels.stable.rust.override {
        extensions = [ "rust-src" ] ++ extensions;
        inherit targets;
      }
  );

  # the combined rust derivation above does contain
  # the source but in form of symlinks, which
  # rust-analyzer does not like so we create a
  # symlink-free version, courtesy of `cp -L`
  rustSrcNoSymlinks = pkgs.stdenv.mkDerivation {
    inherit rust;
    name = "rust-src-no-symlinks";
    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir -p $out
      cp -r -L $rust/lib/rustlib/src/rust/src/. $out/
    '';
  };

  # a derivation for rust-analyzer created from official github releases
  rustAnalyzer = pkgs.stdenv.mkDerivation rec {
    rustSrc = rustSrcNoSymlinks;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    name = "rust-analyzer";
    version = "2020-05-11";
    src = builtins.fetchurl (
      if pkgs.stdenv.isLinux then {
        url = "https://github.com/rust-analyzer/rust-analyzer/releases/download/${version}/rust-analyzer-linux";
        sha256 = "91f5325e5dd0c98d584582d74c71db0f172b3da95ec78bc9973dbc372ce50fd0";
      }
      else {
        url = "https://github.com/rust-analyzer/rust-analyzer/releases/download/${version}/rust-analyzer-mac";
        sha256 = "e9a7e5e92216101862c719a9ad9c51de0cf830bbd2da0a4e864684160fe74bd7";
      }
    );

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir -p $out/bin
      cp $src $out/bin/rust-analyzer-unwrapped
      chmod +x $out/bin/rust-analyzer-unwrapped
      makeWrapper $out/bin/rust-analyzer-unwrapped $out/bin/rust-analyzer \
      --set-default RUST_SRC_PATH "$rustSrc/"
    '';
  };
in
pkgs.stdenv.mkDerivation (
  {
    inherit name;
    src =
      builtins.filterSource
        (
          path: type: !(type == "directory" && baseNameOf path == "target")
          && !(type == "directory" && baseNameOf path == "nix-deps")
          && !(filterLockFile && type == "regular" && baseNameOf path == "Cargo.lock")
        )
        src;
    buildInputs = with pkgs; [
      cacert
      sccache
      rust
    ] ++ buildInputs ++ (pkgs.lib.lists.optionals (defaultTarget == "wasm32-wasi") [ pkgs.wasmer ]);

    shellInputs = [ rustAnalyzer ];

    configurePhase = ''
      mkdir -p nix-deps
      ${builtins.foldl' copyRustDeps "" (
        pkgs.lib.lists.flatten (
            rustDependencies ++ (builtins.map (dep: (collectRustDeps dep)) rustDependencies)
            )
        )
      }
      ${rustPhase}
    '';

    buildPhase = ''
      cargo build --release ${getFeatures buildFeatures}
      sccache -s
    '';

    checkPhase = ''
      cargo fmt -- --check
      cargo test ${getFeatures testFeatures}
      cargo clippy ${getFeatures testFeatures}
      ${extraChecks}
    '';

    installPhase = ''
      mkdir -p $out
    '';

    shellHook = ''
      eval "$configurePhase"
    '';

    # always want backtraces when building or in dev
    RUST_BACKTRACE = 1;
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
