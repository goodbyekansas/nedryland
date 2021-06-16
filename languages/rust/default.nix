{ base, pkgs, versions }:
let
  mkPackage = pkgs.callPackage ./package.nix { inherit base; rustVersion = versions.rust; };
  mkPackageWithStdenv = stdenv: attrs:
    (mkPackage.override
      {
        inherit stdenv;
      }) attrs;

  supportedCrossTargets = {
    windows = {
      stdenv = pkgs.pkgsCross.mingwW64.stdenv;
      attrs = {
        targets = [ "x86_64-pc-windows-gnu" ];
        defaultTarget = "x86_64-pc-windows-gnu";
      };
    };
  };

in
rec {
  inherit mkPackage;

  toApplication = package:
    package.overrideAttrs (
      oldAttrs: {
        installPhase = ''
          ${oldAttrs.installPhase}
          mkdir -p $out/bin
          cp target/${package.defaultTarget or ""}/release/${package.executableName or package.meta.name}${
            if pkgs.lib.hasInfix "-windows-" package.defaultTarget or "" then
              ".exe"
            else
              ""
          } $out/bin
        '';
        shellHook = ''
          ${oldAttrs.shellHook or ""}
          ${builtins.replaceStrings [ "-" ] [ "_" ] package.executableName or package.meta.name}() {
            command cargo run -- "$@"
          }
        '';
      }
    );

  toLibrary = package:
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

  mkLibrary =
    attrs@
    { name
    , src
    , deployment ? { }
    , ...
    }:
    let
      package = toLibrary (mkPackage (
        (builtins.removeAttrs attrs [ "deployment" ]) // {
          filterCargoLock = true;
        }
      ));
    in
    base.mkComponent {
      inherit deployment name package;
      rust = package;
    };

  mkClient =
    attrs@
    { name
    , src
    , deployment ? { }
    , ...
    }:
    let
      pkgAttrs = builtins.removeAttrs attrs [ "deployment" "crossTargets" ];
      package = toApplication (mkPackage pkgAttrs);
      crossTargets = builtins.mapAttrs
        (target: targetAttrs:
          assert pkgs.lib.assertMsg
            (builtins.hasAttr target supportedCrossTargets)
            "Cross compilation target \"${target}\" is not supported!";
          let
            targetSpec = builtins.getAttr target supportedCrossTargets;
          in
          toApplication (mkPackageWithStdenv
            targetSpec.stdenv
            (pkgAttrs // targetAttrs // targetSpec.attrs)
          )
        ) attrs.crossTargets or { };
    in
    base.mkComponent ({
      inherit deployment name package;
      rust = package;
    } // crossTargets);

  mkService = mkClient;

  fromProtobuf =
    { name
    , protoSources
    , version
    , includeServices
    , protoInputs
    , tonicVersion ? "=${versions.tonic}"
    , tonicFeatures ? versions.tonicFeatures
    , tonicBuildVersion ? "=${versions.tonicBuild}"
    }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix
        {
          inherit
            name
            protoSources
            version
            mkClient
            includeServices
            protoInputs
            tonicVersion
            tonicFeatures
            tonicBuildVersion;
          makeSetupHook = pkgs.makeSetupHook;
          pyToml = pkgs.python38Packages.toml;
        };
    in
    mkLibrary
      {
        inherit version;
        name = "${name}-rust-protobuf";
        src = generatedCode;
        propagatedBuildInputs = builtins.map (pi: pi.rust.package) protoInputs;
      };
}
