pkgs: base: attrs@{ name, src, buildInputs ? [], extensions ? [], targets ? [], hasTests ? true, rustDependencies ? [], defaultTarget ? "", useNightly ? "", filterLockFile ? false, ... }:
let
  safeAttrs = (builtins.removeAttrs attrs [ "rustDependencies" ]);
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
      rm -rf "$PACKAGE_PATH"
      cp -r ${right.package} "$PACKAGE_PATH"
      echo "${right.package}" > "$FILE_NAME"
      chmod 0444 "$FILE_NAME"
    else
      echo "🧾 Skipping copying ${right.package.name} since it's already up to date."
    fi
  '';
in
base.mkComponent {
  package = pkgs.stdenv.mkDerivation (
    safeAttrs // {
      inherit name;
      src = builtins.filterSource
        (path: type: !(type == "directory" && baseNameOf path == "target") && !(filterLockFile && type == "regular" && baseNameOf path == "Cargo.lock")) src;
      buildInputs = with pkgs; [
        cacert
        sccache
        (
          if useNightly != "" then
            (
              rustChannelOf {
                date = useNightly;
                channel = "nightly";
              }
            ).rust.override {
              extensions = [ "rust-src" ] ++ extensions;
              inherit targets;
            }
          else
            latest.rustChannels.stable.rust.override {
              extensions = [ "rust-src" ] ++ extensions;
              inherit targets;
            }
        )
      ] ++ buildInputs;

      configurePhase = ''
        mkdir -p nix-deps

        ${builtins.foldl' copyRustDeps "" rustDependencies}
        ${rustPhase}
      '';

      buildPhase = ''
        cargo build --release
        sccache -s
      '';

      checkPhase = ''
        cargo fmt -- --check
        ${if hasTests then "cargo test" else ""}
        cargo clippy
      '';

      installPhase = ''
        mkdir -p $out
      '';

      shellHook = ''
        eval "$configurePhase"
      '';

      # always want backtraces when building or in dev
      RUST_BACKTRACE = 1;
    } // (if defaultTarget != "" then { CARGO_BUILD_TARGET = defaultTarget; } else {})
  );
}
