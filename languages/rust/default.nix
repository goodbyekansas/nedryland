{ base, pkgs }:
rec {
  mkRustComponent = import ./component.nix pkgs base;
  mkRustFunction = { name, src, manifest, buildInputs ? [], extensions ? [], targets ? [] }:
    let
      component = mkRustComponent {
        inherit name src buildInputs extensions;
        targets = [ "wasm32-wasi" ];
      };
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            cp target/wasm32-wasi/release/*.wasm $out/bin
          '';
        }
      );
    in
      base.mkFunction { inherit manifest name; package = newPackage; };
}
