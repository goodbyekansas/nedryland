pkgs: base: { name, src, buildInputs ? [], extensions ? [], targets ? [] }:
base.mkComponent {
  package = pkgs.stdenv.mkDerivation {
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
      export HOME=$PWD

      cargo fmt -- --check

      cargo clippy
    '';

    installPhase = ''
      mkdir -p $out/bin
    '';

    # always want backtraces when building or in dev
    RUST_BACKTRACE = 1;
  };
}
