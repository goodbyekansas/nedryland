{ base, pkgs }:
rec {
  mkRustComponent = import ./component.nix pkgs base;

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
