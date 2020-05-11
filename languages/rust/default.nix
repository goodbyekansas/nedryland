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
    , hasTests ? true
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
          hasTests
          ;
        filterLockFile = true;
      };
      newPackage = package.overrideAttrs
        (
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
    }:
    let
      package = mkPackage {
        inherit name src buildInputs rustDependencies extensions targets useNightly;
      };
      newPackage = package.overrideAttrs
        (
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
    }:
    let
      package = mkPackage {
        inherit name src buildInputs rustDependencies extensions targets useNightly;
      };
      newPackage = package.overrideAttrs
        (
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
