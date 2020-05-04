{ base, pkgs }:
rec {
  mkComponent = import ./component.nix pkgs base;

  mkUtility = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], libraryName ? name, defaultTarget ? "", ... }:
    let
      component = mkComponent attrs;
      newPackage = component.package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out
            cp -r $src $out
          '';
        }
      );
    in
      base.mkComponent { inherit deployment; package = newPackage; };

  mkClient = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], executableName ? name, ... }:
    let
      component = mkComponent attrs;
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

  mkService = attrs@{ name, src, deployment ? {}, buildInputs ? [], extensions ? [], targets ? [], executableName ? name, ... }:
    let
      component = mkComponent attrs;
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
