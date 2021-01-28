{ base, pkgs }:
rec {
  mkPackage = pkgs.callPackage ./package.nix { inherit base; };
  toUtility = package:
    let
      checksumHook = pkgs.makeSetupHook
        {
          name = "generate-cargo-checksums";
          deps = [ pkgs.jq pkgs.coreutils ];
        }
        ./generateCargoChecksums.sh;
    in
    package.overrideAttrs (
      oldAttrs: {

        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ checksumHook ];
        buildPhase = ''
          runHook preBuild
          cargo package --no-verify --no-metadata
          runHook postBuild
        '';

        installPhase = ''
          mkdir -p $out/src/rust

          for crate in target/package/*.crate; do
            tar -xzf $crate -C $out/src/rust
          done
        '';
      }
    );

  mkUtility =
    attrs@{ name
    , src
    , deployment ? { }
    , ...
    }:
    let
      package = mkPackage (attrs // {
        filterCargoLock = true;
      });
    in
    base.mkComponent { inherit deployment; package = (toUtility package); };

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

  fromProtobuf = { name, protoSources, version, includeServices, protoInputs }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit name protoSources version mkClient includeServices protoInputs; };
    in
    mkUtility { inherit name version; src = generatedCode; propagatedBuildInputs = builtins.map (pi: pi.rust.package) protoInputs; };
}
