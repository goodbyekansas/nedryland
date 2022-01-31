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
        buildInputs = [ pkgs.pkgsCross.mingwW64.windows.pthreads ];
      };
    };
  };

  getNativeTarget = attrs: package:
    pkgs.lib.optionalAttrs (pkgs.lib.attrByPath [ "crossTargets" "includeNative" ] true attrs) {
      inherit package;
    };

  mkDocs = attrs@{ name, targets, ... }:
    let
      includeNativeDocs = (!attrs ? crossTargets || attrs.crossTargets.includeNative or true);
      targetNames = (pkgs.lib.optional includeNativeDocs pkgs.stdenv.buildPlatform.config) ++ targets;
    in
    assert pkgs.lib.assertMsg (targetNames != [ ])
      "${name} needs to have at least one target";
    mkPackage (builtins.removeAttrs attrs [ "docs" "crossTargets" ] // {
      name = "${name}-api-reference";
      # Build documentation for cross targets.
      buildPhase =
        builtins.concatStringsSep "\n" (builtins.map
          (tar:
            "cargo doc --workspace --no-deps --all-features --target=${tar}"
          )
          targetNames);

      nativeBuildInputs = with pkgs;[ j2cli jq ] ++ attrs.nativeBuildInputs or [ ];

      inherit targetNames;

      installPhase = ''
        export outPath=$(realpath -m $out/share/doc/${name}/api)
        mkdir -p $outPath
        pushd target/${builtins.head targetNames}/doc 2>&1 >/dev/null
        find . \( -type d -path "./src" -o -type f -mindepth 1 -maxdepth 1 \) -exec cp -r {} $outPath/ \;
        popd 2>&1 >/dev/null
      ''
      # Copy docs from cross targets and append target triple name to the docs folder.
      + builtins.concatStringsSep "\n" (builtins.map
        (tar: ''
          pushd target/${tar}/doc/ 2>&1 > /dev/null
          find . -type d -path "./src" -prune -o -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cp -r $0 $(realpath -m "$outPath/$0-${tar}")' {} +
          popd 2>&1 > /dev/null
        '')
        targetNames)
      + ''
        crateNames=$(cargo metadata --format-version=1 --no-deps | jq -r '.packages[].name')
        echo "title: ${name}" > data.yml
        echo "links:" >> data.yml
        for crateName in $crateNames; do
          for targetName in $targetNames; do
            echo "  - name: $crateName ($targetName)" >> data.yml
            echo "    href: ''${crateName//-/_}-$targetName" >> data.yml
          done
        done
        j2 ${./docs/index.html} data.yml -o $out/share/doc/${name}/api/index.html
      '';
    });

  getTargetSpec = target:
    assert pkgs.lib.assertMsg
      (builtins.hasAttr target supportedCrossTargets)
      "Cross compilation target \"${target}\" is not supported!";
    builtins.getAttr target supportedCrossTargets;

  toCrossTargets = crossTargets: pkgAttrs: intoFunction: builtins.mapAttrs
    (target: targetAttrs':
      let
        targetAttrs = if builtins.isAttrs targetAttrs' then targetAttrs' else { };
        targetSpec = getTargetSpec target;
        buildInputs = (targetSpec.attrs.buildInputs or [ ]) ++
          (pkgAttrs.buildInputs or [ ]) ++
          (targetAttrs.buildInputs or [ ]);
      in
      intoFunction (mkPackageWithStdenv
        targetSpec.stdenv
        (pkgAttrs // targetAttrs // targetSpec.attrs // { inherit buildInputs; })
      )
    )
    (builtins.removeAttrs crossTargets [ "includeNative" ]);

  mkComponentWith = func: toFunction:
    attrs@ { name, deployment ? { }, ... }:
    let
      pkgAttrs = builtins.removeAttrs attrs [ "deployment" "crossTargets" ];
      crossTargets = toCrossTargets (attrs.crossTargets or { }) pkgAttrs toFunction;
      nativeTarget = getNativeTarget attrs (toFunction (mkPackage pkgAttrs));
      apiDocs = mkDocs (attrs // {
        targets = pkgs.lib.flatten (builtins.map (target: (getTargetSpec target).attrs.targets) (builtins.attrNames (builtins.removeAttrs attrs.crossTargets or { } [ "includeNative" ])));
      });
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
