pkgs: rust: { name, buildInputs, propagatedBuildInputs }:
let
  internalSetupHook = pkgs.makeSetupHook
    {
      name = "internal-deps-hook";
    }
    ./internalDepsSetupHook.sh;
in
# derivation that creates a fake vendor dir
  # with our internal nix dependencies
pkgs.stdenv.mkDerivation {
  name = "${name}-internal-deps";
  inherit buildInputs propagatedBuildInputs;

  phases = [ "buildPhase" "installPhase" ];
  nativeBuildInputs = with pkgs; [ git cacert rust internalSetupHook ];

  buildPhase = ''
    if [ -n "''${rustDependencies}" ]; then
      echo "🏡 vendoring internal dependencies..."

      mkdir -p vendored

      # symlink in all deps
      for dep in $rustDependencies; do
        ln -sf "$dep" ./vendored/
      done

      echo "🏡 internal dependencies vendored!"
    fi
  '';

  installPhase = ''
    mkdir $out

    if [ -d vendored ]; then
      cp -r vendored $out
      substitute ${./cargo-internal.config.toml} $out/cargo.config.toml \
       --subst-var-by vendorDir $out/vendored

      mkdir -p "$out/nix-support"
      substituteAll "$setupHook" "$out/nix-support/setup-hook"
    fi
  '';

  setupHook = ./setupHook.sh;
}
