{ base, pkgs, versions }:
let

  # the toRustTarget function in nixpkgs handles wasi incorrectly, patch it here
  toRustTarget = target: builtins.replaceStrings [ "wasm32-unknown-wasi" ] [ "wasm32-wasi" ] (pkgs.rust.toRustTarget target);

  mkPackage = pkgs.callPackage ./package.nix { inherit base; rustVersion = versions.rust; inherit toRustTarget; };

  supportedCrossTargets = {
    windows = {
      stdenv = pkgs.pkgsCross.mingwW64.stdenv;
      attrs = {
        buildInputs = [ pkgs.pkgsCross.mingwW64.windows.pthreads ];
      };
    };

    wasi = {
      stdenv = pkgs.pkgsCross.wasi32.clang12Stdenv;
      attrs = { };
    };

    # package is always the default target.
    _default = {
      output = "package";
      stdenv = pkgs.stdenv;
      attrs = { };
    };
  };

  toDocs = targetSpecs: pkgAttrs@{ name, ... }:
    assert pkgs.lib.assertMsg (targetSpecs != { })
      "${name} needs to have at least one target to build documentation";
    let

      docDrvs = builtins.mapAttrs
        (targetName: targetSpec:
          let
            componentTargetName = targetSpec.output or targetName;
          in
          mkPackage.override { stdenv = targetSpec.stdenv; } (pkgAttrs // {
            inherit componentTargetName;
            name = "${name}-api-reference-${componentTargetName}";
            dontFixup = true;
            buildPhase = "cargo doc --workspace --no-deps --all-features";
            installPhase =
              ''
                export outPath=$(realpath -m $out/share/doc/${name}/api)
                crateNames=$(cargo metadata --format-version=1 --no-deps | ${pkgs.jq}/bin/jq -r '.packages[].name')
                mkdir -p $outPath
                cp -r target/*/doc/. $outPath
                for crate in $crateNames; do
                  mv $outPath/''${crate//-/_} $outPath/''${crate//-/_}-${toRustTarget targetSpec.stdenv.hostPlatform}
                done
                echo $crateNames > $outPath/crate_names
              '';
          })
        )
        targetSpecs;
    in
    pkgs.symlinkJoin {
      name = "${name}-api-reference";
      paths = builtins.attrValues docDrvs;
      # Create an index HTML page for all targets. If there is only one target, the index
      # page will only contain a redirect to the single target (this is handled in the
      # html template)
      targets = pkgs.lib.mapAttrsToList (_targetName: targetSpec: toRustTarget targetSpec.stdenv.hostPlatform) targetSpecs;
      passthru = docDrvs;
      postBuild = ''
        crateNames=$(cat $out/share/doc/${name}/api/crate_names)
        echo "title: ${name}" > data.yml
        echo "links:" >> data.yml
        for crateName in $crateNames; do
          for targetName in $targets; do
            echo "  - name: $crateName ($targetName)" >> data.yml
            echo "    href: ''${crateName//-/_}-$targetName" >> data.yml
          done
        done
        ${pkgs.j2cli}/bin/j2 ${./docs/index.html} data.yml -o $out/share/doc/${name}/api/index.html
      '';
    };

  toPackages = targetSpecs: pkgAttrs: pkgPostHook: pkgs.lib.mapAttrs'
    (target: targetSpec:
      rec {
        name = targetSpec.output or target;
        value = pkgPostHook
          (mkPackage.override
            { stdenv = targetSpec.stdenv; }
            # note that the target spec attrs _override_ the sent in pkg attrs
            (pkgAttrs // targetSpec.attrs // { componentTargetName = name; })
          );
      }
    )
    targetSpecs;

  getTargetSpec = target:
    assert pkgs.lib.assertMsg
      (builtins.hasAttr target supportedCrossTargets)
      "Cross compilation target \"${target}\" is not supported!";
    builtins.getAttr target supportedCrossTargets;

  toTargetSpec = targetName: targetAttrs:
    let
      targetAttrs' = if builtins.isAttrs targetAttrs then targetAttrs else { };
    in
    # If the user has created their own crossTarget just take as is.
    (if targetAttrs'.type or "" == "target-spec" then
      targetAttrs' else
      let
        targetSpec = getTargetSpec targetName;
        targetAttrsResult = if builtins.isFunction targetAttrs then (targetAttrs targetSpec.attrs) else targetAttrs';
      in
      (targetSpec // {
        attrs = targetSpec.attrs // targetAttrsResult;
      })
    );

  mkComponentWith = componentFactory: packagePostHook:
    attrs@ { name, deployment ? { }, ... }:
    let
      pkgAttrs = builtins.removeAttrs attrs [ "deployment" "crossTargets" "defaultTarget" ];
      defaultTarget = attrs.defaultTarget or "_default";
      defaultTargetKey = if builtins.isString (defaultTarget) then defaultTarget else "package";

      # Convert all members in the crossTargets set to targetSpecs and append
      # defaultTarget which will be either unset, a known cross target or an inline target
      # spec. If it is unset, we use the special known cross target '_default'.
      targetSpecs = builtins.mapAttrs
        toTargetSpec
        (attrs.crossTargets or { } // { "${defaultTargetKey}" = defaultTarget; });

      targets = toPackages targetSpecs pkgAttrs packagePostHook;
      apiDocs = toDocs targetSpecs pkgAttrs;
    in
    componentFactory ({
      inherit deployment name;
      rust = builtins.attrValues targets;
    } // targets // {
      docs = {
        api = apiDocs;
      } // (attrs.docs or { });
    });
in
rec {
  inherit supportedCrossTargets toRustTarget;

  mkComponent = attrs@{ nedrylandType, ... }:
    let
      attrs' = builtins.removeAttrs attrs [ "nedrylandType" ];
    in
    mkComponentWith (attrs: base.mkComponent (attrs // { inherit nedrylandType; })) (su: su) attrs';

  mkCrossTarget = { stdenv, extraTargets ? [ ], output ? null, buildInputs ? [ ] }:
    {
      inherit stdenv;
      type = "target-spec";

      attrs = {
        inherit extraTargets;
      } // pkgs.lib.optionalAttrs (buildInputs != [ ]) { inherit buildInputs; };
    } // pkgs.lib.optionalAttrs (output != null) { inherit output; };

  toApplication = package:
    package.overrideAttrs (
      oldAttrs: {
        installPhase =
          let
            executableName = package.executableName or package.meta.name;
            executableExtension = pkgs.lib.optionalString (package.stdenv.hostPlatform.isWindows) ".exe";
          in
          ''
            ${oldAttrs.installPhase or ""}
            mkdir -p $out/bin
            cp target/''${CARGO_BUILD_TARGET:-}/release/${executableName}${executableExtension} $out/bin
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

        nativeBuildInputs = oldAttrs.nativeBuildInputs
          ++ [
          (pkgs.makeSetupHook
            {
              name = "generate-cargo-checksums";
              deps = [ pkgs.jq pkgs.coreutils ];
            } ./generateCargoChecksums.sh)
        ];

        buildPhase = ''
          runHook preBuild
          cargo package --no-verify --no-metadata
          runHook postBuild
        '';

        installPhase = ''
          ${oldAttrs.installPhase or ""}
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
