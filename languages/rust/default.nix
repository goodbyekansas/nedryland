{ base, pkgs, versions }:
let
  mkPackage = pkgs.callPackage ./package.nix { inherit base; rustVersion = versions.rust; };
  mkPackageWithStdenv = stdenv:
    mkPackage.override
      {
        inherit stdenv;
      };

  supportedCrossTargets = {
    windows = {
      stdenv = pkgs.pkgsCross.mingwW64.stdenv;
      attrs = {
        targets = [ "x86_64-pc-windows-gnu" ];
        defaultTarget = "x86_64-pc-windows-gnu";
      };
    };
  };

  getNativeTarget = attrs: package:
    pkgs.lib.optionalAttrs (pkgs.lib.attrByPath [ "crossTargets" "includeNative" ] true attrs) {
      inherit package;
    };

  toDocs = package:
    package.overrideAttrs (
      oldAttrs: {
        buildPhase = ''
          cargo doc --workspace --no-deps --all-features
        '';
        installPhase = ''
          mkdir -p $out/share/doc/api/${oldAttrs.name}
          cp -r target/''${CARGO_BUILD_TARGET:-}/doc/. $out/share/doc/api/${oldAttrs.name}
        '';
      }
    );


  mkDocs = attrs@{ name, ... }:
    mkPackage (builtins.removeAttrs attrs [ "docs" ] // {
      name = "${name}-api-reference";
      buildPhase = ''
        cargo doc --workspace --no-deps --all-features
      '';
      installPhase = ''
        mkdir -p $out/share/doc/api/${name}
        cp -r target/''${CARGO_BUILD_TARGET:-}/doc/. $out/share/doc/api/${name}
      '';
    });

  toCrossTargets = crossTargets: pkgAttrs: intoFunction: builtins.mapAttrs
    (target: targetAttrs:
      assert pkgs.lib.assertMsg
        (builtins.hasAttr target supportedCrossTargets)
        "Cross compilation target \"${target}\" is not supported!";
      let
        targetSpec = builtins.getAttr target supportedCrossTargets;
      in
      intoFunction (mkPackageWithStdenv
        targetSpec.stdenv
        (pkgAttrs // targetAttrs // targetSpec.attrs)
      )
    )
    (builtins.removeAttrs crossTargets [ "includeNative" ]);

  mkComponentWith = func: toFunction:
    attrs@ { name, deployment ? { }, ... }:
    let
      pkgAttrs = builtins.removeAttrs attrs [ "deployment" "crossTargets" ];
      crossTargets = toCrossTargets (attrs.crossTargets or { }) pkgAttrs toFunction;
      crossDocs = toCrossTargets (attrs.crossTargets or { }) pkgAttrs toDocs;
      nativeTarget = getNativeTarget attrs (toFunction (mkPackage pkgAttrs));
      apiDocs =
        pkgs.lib.optionalAttrs (pkgs.lib.attrByPath [ "crossTargets" "includeNative" ] true attrs)
          {
            package = mkDocs pkgAttrs;
          } // crossDocs;
    in
    func ({
      inherit deployment name;
      rust = builtins.attrValues crossTargets ++ builtins.attrValues nativeTarget;
    } // crossTargets // nativeTarget //
    {
      docs = {
        api = apiDocs;
      } // (attrs.docs or { });
    }
    );

  checksumHook = pkgs.makeSetupHook
    {
      name = "generate-cargo-checksums";
      deps = [ pkgs.jq pkgs.coreutils ];
    }
    ./generateCargoChecksums.sh;
in
rec {
  inherit mkPackage mkDocs;

  toApplication = package:
    package.overrideAttrs (
      oldAttrs: {
        installPhase = ''
          ${oldAttrs.installPhase}
          mkdir -p $out/bin
          cp target/''${CARGO_BUILD_TARGET:-}/release/${package.executableName or package.meta.name}${
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

  mkLibrary = attrs:
    mkComponentWith base.mkLibrary toLibrary (attrs // {
      filterCargoLock = true;
    });

  mkClient = mkComponentWith base.mkClient toApplication;

  mkService = mkComponentWith base.mkService toApplication;

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
            base
            name
            protoSources
            version
            includeServices
            protoInputs
            tonicVersion
            tonicFeatures
            tonicBuildVersion;
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
