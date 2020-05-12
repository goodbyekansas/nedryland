{ base, pkgs }:
rec {
  mkPackage = import ./package.nix pkgs base;

  mkUtility =
    attrs@{ name
    , src
    , deployment ? { }
    , buildInputs ? [ ]
    , rustDependencies ? [ ]
    , extensions ? [ ]
    , targets ? [ ]
    , libraryName ? name
    , defaultTarget ? ""
    , useNightly ? ""
    , extraChecks ? ""
    , buildFeatures ? [ ]
    , testFeatures ? [ ]
    }:
    let
      package = mkPackage {
        inherit
          name
          src
          buildInputs
          rustDependencies
          extensions
          targets
          defaultTarget
          useNightly
          extraChecks
          buildFeatures
          testFeatures
          ;
        filterLockFile = true;
      };

      newPackage = package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out

            cp -r $src/* $out
          '';
        }
      );
    in
    base.mkComponent (attrs // { inherit deployment; package = newPackage; });

  mkClient =
    attrs@{ name
    , src
    , deployment ? { }
    , buildInputs ? [ ]
    , rustDependencies ? [ ]
    , extensions ? [ ]
    , targets ? [ ]
    , executableName ? name
    , useNightly ? ""
    , extraChecks ? ""
    , buildFeatures ? [ ]
    , testFeatures ? [ ]
    }:
    let
      package = mkPackage {
        inherit name src buildInputs rustDependencies extensions targets useNightly extraChecks buildFeatures testFeatures;
      };

      newPackage = package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out/bin
            cp target/release/${executableName} $out/bin
          '';
        }
      );
    in
    base.mkClient (attrs // { inherit deployment; package = newPackage; });

  mkService =
    attrs@{ name
    , src
    , deployment ? { }
    , buildInputs ? [ ]
    , rustDependencies ? [ ]
    , extensions ? [ ]
    , targets ? [ ]
    , executableName ? name
    , useNightly ? ""
    , extraChecks ? ""
    , buildFeatures ? [ ]
    , testFeatures ? [ ]
    }:
    let
      package = mkPackage {
        inherit name src buildInputs rustDependencies extensions targets useNightly extraChecks buildFeatures testFeatures;
      };

      newPackage = package.overrideAttrs (
        oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}
            mkdir -p $out/bin
            cp target/release/${name} $out/bin
          '';
        }
      );
    in
    base.mkService (attrs // { inherit deployment; package = newPackage; });
}
