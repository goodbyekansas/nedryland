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
    , ...
    }:
    let
      package = mkPackage (attrs // {
        vendorDependencies = false;
      });

      checksumHook = pkgs.makeSetupHook
        {
          name = "generate-cargo-checksums";
          deps = [ pkgs.jq pkgs.coreutils ];
        }
        ./generateCargoChecksums.sh;
      newPackage = package.overrideAttrs (
        oldAttrs: {

          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ checksumHook ];
          buildPhase = attrs.buildPhase or ''
            runHook preBuild
            cargo package --no-verify --no-metadata
            runHook postBuild
          '';

          installPhase = attrs.installPhase or ''
            mkdir -p $out/src/rust

            for crate in target/package/*.crate; do
              tar -xzf $crate -C $out/src/rust
            done

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
    , ...
    }:
    let
      package = mkPackage (attrs // {
        inherit name src buildInputs rustDependencies extensions targets useNightly extraChecks buildFeatures testFeatures;
      });

      newPackage = package.overrideAttrs (
        oldAttrs: {
          installPhase = attrs.installPhase or ''
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
    , ...
    }:
    let
      package = mkPackage (attrs // {
        inherit name src buildInputs rustDependencies extensions targets useNightly extraChecks buildFeatures testFeatures;
      });

      newPackage = package.overrideAttrs (
        oldAttrs: {
          installPhase = attrs.installPhase or ''
            ${oldAttrs.installPhase}
            mkdir -p $out/bin
            cp target/release/${name} $out/bin
          '';
        }
      );
    in
    base.mkService (attrs // { inherit deployment; package = newPackage; });
}
