pkgs: base: attrs@{ name, src, buildInputs ? [], extensions ? [], targets ? [], hasTests ? true, ... }:
base.mkComponent {
  package = pkgs.stdenv.mkDerivation (
    attrs // {
      inherit name;
      src = builtins.filterSource
        (path: type: (type != "directory" || baseNameOf path != "target")) src;
      buildInputs = with pkgs; [
        cacert
        (
          latest.rustChannels.stable.rust.override {
            extensions = [ "rust-src" ] ++ extensions;
            inherit targets;
          }
        )
      ] ++ buildInputs;

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
        mkdir -p $out/bin
      '';

      # always want backtraces when building or in dev
      RUST_BACKTRACE = 1;
    }
  );
}
