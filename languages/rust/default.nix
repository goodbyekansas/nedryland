{ base, pkgs }:
rec {
  mkRustComponent = import ./component.nix pkgs base;
  mkRustFunction = attrs@{ name, src, manifest, buildInputs ? [], extensions ? [], targets ? [], ... }:
    let
      component = mkRustComponent (
        attrs // {
          targets = targets ++ [ "wasm32-wasi" ];
          hasTests = false;
        }
      );
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

  mkRustClient = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], executableName ? name, ... }:
    let
      component = mkRustComponent attrs;
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            cp target/release/${name} $out/bin
          '';
        }
      );
    in
      base.mkClient { inherit name deployment; package = newPackage; };

  mkRustService = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], executableName ? name, ... }:
    let
      component = mkRustComponent attrs;
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            cp target/release/${name} $out/bin
          '';
        }
      );
    in
      base.mkService { inherit name deployment; package = newPackage; };
}
