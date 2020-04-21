pkgs: base: attrs@{ name, src, buildInputs ? [], extensions ? [], targets ? [], hasTests ? true, rustDependencies ? [], defaultTarget ? "", useNightly ? "", ... }:
let
  safeAttrs = (builtins.removeAttrs attrs [ "rustDependencies" ]);
  rustPhase = ''
    if [ -z $IN_NIX_SHELL ]; then
      sccache --stop-server 2>&1 > /dev/null || true
      export RUSTC_WRAPPER=sccache

      home_cache="${builtins.getEnv "HOME"}/.cache/nedryland-rust"
      var_cache="/var/cache/nedryland-rust"
      tmp_cache="/tmp/cache/nedryland-rust"

      if [ -w "$(dirname "$home_cache")" ]; then # Home folder
           echo "Using rust cache directory \"$home_cache\""
           SCCACHE_DIR="$home_cache" sccache --start-server
      elif [ -w "$var_cache" ]; then
           echo "Using rust cache directory \"$var_cache\""
           SCCACHE_DIR="$var_cache" sccache --start-server
      else
           echo "Using rust cache directory \"$tmp_cache\""
           echo "WARNING: Using fallback cache location.
           If you are running single user nix install check
           the permissions of your home folder. If you are
           running multi user nix install we use the
           location \"$var_cache\", please make sure that
           folder exists and is writable by the group \"$(id -gn)\""

           SCCACHE_DIR="$tmp_cache" sccache --start-server
      fi
      export HOME=$PWD
    fi
  '';
in
base.mkComponent {
  package = pkgs.stdenv.mkDerivation (
    safeAttrs // {
      inherit name;
      src = builtins.filterSource
        (path: type: (type != "directory" || baseNameOf path != "target")) src;
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
        rm -rf nix-deps
        mkdir -p nix-deps
        ${builtins.foldl' (left: right: "${left}\n ln -s ${right.package.src} nix-deps/${right.package.name}") "" rustDependencies}
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
