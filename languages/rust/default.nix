{ base, pkgs }:
rec {
  mkRustComponent = import ./component.nix pkgs base;

  mkRustUtility = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], libraryName ? name, defaultTarget ? "", ... }:
    let
      component = mkRustComponent attrs;
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out/lib
            cp target${(if defaultTarget != "" then "/" + defaultTarget else "")}/release/lib${libraryName}.rlib $out/lib
          '';
        }
      );
    in
      base.mkComponent { inherit deployment; package = newPackage; };

  mkRustClient = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], executableName ? name, ... }:
    let
      component = mkRustComponent attrs;
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out/bin
            cp target/release/${executableName} $out/bin
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
            mkdir -p $out/bin
            cp target/release/${name} $out/bin
          '';
        }
      );
    in
      base.mkService { inherit name deployment; package = newPackage; };
}
