pkgs: base: attrs@{ name, src, buildInputs ? [], extensions ? [], targets ? [], hasTests ? true, rustDependencies ? [], defaultTarget ? "", useNightly ? "", ... }:
let
  safeAttrs = (builtins.removeAttrs attrs [ "rustDependencies" ]);
in
base.mkComponent {
  package = pkgs.stdenv.mkDerivation (
    safeAttrs // {
      inherit name;
      src = builtins.filterSource
        (path: type: (type != "directory" || baseNameOf path != "target")) src;
      buildInputs = with pkgs; [
        cacert
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
        export HOME=$PWD
        cargo build --release
      '';

      checkPhase = ''
        if [ -z $IN_NIX_SHELL ]; then
          export HOME="$PWD"
        fi

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
