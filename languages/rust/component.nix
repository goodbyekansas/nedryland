pkgs: base: attrs@{ name, src, buildInputs ? [], extensions ? [], targets ? [], hasTests ? true, rustDependencies ? [], defaultTarget ? "", useNightly ? "", ... }:
let
  safeAttrs = (builtins.removeAttrs attrs [ "rustDependencies" ]);
  rustPhase = ''
    if [ -z $IN_NIX_SHELL ]; then
      sccache --stop-server 2>&1 > /dev/null | true
      export RUSTC_WRAPPER=sccache
      SCCACHE_DIR=${builtins.getEnv "HOME"}/.cache/sccache/ sccache --start-server
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
      '';

      buildPhase = ''
        ${rustPhase}
        cargo build --release
        sccache -s
      '';

      checkPhase = ''
        ${rustPhase}
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
