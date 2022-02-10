{ pkgs
, base
, stdenv
, lib
, buildPackages
, rustVersion
, toRustTarget
}:

attrs@{ name
, componentTargetName
, srcExclude ? [ ]
, extensions ? [ ]
, extraTargets ? [ ]
, useNightly ? ""
, extraChecks ? ""
, buildFeatures ? [ ]
, testFeatures ? [ ]
, shellHook ? ""
, warningsAsErrors ? true
, filterCargoLock ? false
, ...
}:
let

  # host = the platform that the resulting binary will run on (i.e. the host platform of
  # the produced artifact, not our host platform)
  # build = the platform we are building on
  hostTriple = toRustTarget stdenv.hostPlatform;
  buildTriple = toRustTarget stdenv.buildPlatform;

  extraTargets' = extraTargets ++ lib.optional (buildTriple != hostTriple) hostTriple;

  # this controls the version of rust to use
  rustBin = ((
    if useNightly != "" then
      (
        pkgs.rust-bin.nightly."${useNightly}".default.override {
          inherit extensions;
          targets = extraTargets';
        }
      )
    else
      (
        pkgs.rust-bin.stable."${rustVersion.stable}".default.override {
          inherit extensions;
          targets = extraTargets';
        }
      )
  ).overrideAttrs (_: {
    # TODO: This is a workaround for cross compilation where the build platform compiler
    # seems to use dependencies for the target platform. This probably has to do with our
    # lack of splicing below. Investigate later.
    propagatedBuildInputs = [ ];
  }));

  rustAnalyzer = pkgs.rust-bin.nightly."${rustVersion.analyzer}".rust-analyzer-preview;

  commands = ''
    check() {
        eval "$checkPhase"
    }

    build() {
        eval "$buildPhase"
    }

    run() {
        cargo run "$@"
    }
  '';

  resolveBuildInputs = typeName: builtins.map
    (input:
      if input ? isNedrylandComponent then
        input."${componentTargetName}"
          or input.package
          or (abort "${name} could not auto-detect target for ${typeName} \"${input.name}\", please specify manually (tried \"${componentTargetName}\" and \"package\")")
      else
        input
    );

  resolveNativeBuildInputs = typeName: builtins.map
    (input:
      if input ? isNedrylandComponent then
        input.package or (abort "${name} could not find \"package\" target for ${typeName} \"${input.name}\", please specify manually")
      else
        input
    );

  buildInputs = resolveBuildInputs "buildInput" attrs.buildInputs or [ ];
  propagatedBuildInputs = resolveBuildInputs "propagatedBuildInput" attrs.propagatedBuildInputs or [ ];
  shellInputs = resolveNativeBuildInputs "shellInput" attrs.shellInputs or [ ];
  nativeBuildInputs = resolveNativeBuildInputs "nativeBuildInput" attrs.nativeBuildInputs or [ ];
  checkInputs = resolveNativeBuildInputs "checkInput" attrs.checkInputs or [ ];

  vendor = import ./vendor.nix pkgs rustBin {
    inherit name buildInputs propagatedBuildInputs;
    extraCargoConfig = attrs.extraCargoConfig or "";
  };

  getFeatures = features:
    if (builtins.length features) == 0 then
      ""
    else
      ''--features "${(builtins.concatStringsSep " " features)}"'';


  # rust-analyzer cannot handle symlinks
  # so we need to create a derivation with the
  # correct rust source without symlinks
  rustSrcNoSymlinks = pkgs.stdenv.mkDerivation {
    name = "rust-src-no-symlinks";

    rustWithSrc = (rustBin.override {
      extensions = [ "rust-src" ] ++ extensions;
    });
    rust = rustBin;

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir -p $out
      cp -r -L $rustWithSrc/lib/rustlib/src/rust/library/. $out/
    '';
  };

  cargoAlias = ''
    cargo()
    {
    subcommand="$1"
    if [ $# -gt 0 ] && ([ "$subcommand" == "test" ] || [ "$subcommand" == "clippy" ]) ; then
      shift
      command cargo "$subcommand" ${getFeatures testFeatures} "$@"
    elif [ $# -gt 0 ] && ([ "$subcommand" == "build" ] || [ "$subcommand" == "run" ]) ; then
      shift
      command cargo "$subcommand" ${getFeatures buildFeatures} "$@"
    else
      command cargo "$@"
    fi
    }
  '';

  safeAttrs = builtins.removeAttrs attrs [ "extraChecks" "testFeatures" "buildFeatures" "srcExclude" "shellInputs" "docs" "componentTargetName" ];

  # cross compilation settings
  ccForBuild = "${buildPackages.stdenv.cc.targetPrefix}cc";
  cxxForBuild = "${buildPackages.stdenv.cc.targetPrefix}c++";
  linkerForBuild = ccForBuild;

  ccForHost = "${stdenv.cc.targetPrefix}cc";
  cxxForHost = "${stdenv.cc.targetPrefix}c++";
  linkerForHost = ccForHost;

  runners = builtins.map
    (runner: pkgs.callPackage runner.path { })
    (builtins.filter (runner: runner.predicate) [
      {
        path = ./runner/wasi.nix;
        predicate = stdenv.hostPlatform.isWasi;
      }
      {
        path = ./runner/windows.nix;
        predicate = (lib.inNixShell && stdenv.hostPlatform.isWindows);
      }
    ]);

in
base.mkDerivation
  (
    safeAttrs // {
      inherit stdenv propagatedBuildInputs checkInputs;
      strictDeps = true;
      disallowedReferences = [ vendor ];
      srcFilter = path: type: !(type == "directory" && baseNameOf path == "target")
      && !(type == "directory" && baseNameOf path == ".cargo")
      && !(filterCargoLock && type == "regular" && baseNameOf path == "Cargo.lock")
      && !(builtins.any (pred: pred path type) srcExclude);
      vendoredDependencies = vendor;

      nativeBuildInputs = with pkgs; [
        cacert
        rustBin
        removeReferencesTo
        vendor
      ]
      ++ runners
      ++ nativeBuildInputs;

      buildInputs = buildInputs
      ++ (lib.optional stdenv.hostPlatform.isWindows pkgs.pkgsCross.mingwW64.windows.pthreads);

      passthru = { shellInputs = (shellInputs ++ [ rustSrcNoSymlinks rustAnalyzer ]); };

      depsBuildBuild = pkgs.lib.optionals stdenv.buildPlatform.isDarwin [
        # this is actually not always needed but life is
        # too short to figure out when so let's always
        # add it
        buildPackages.darwin.apple_sdk.frameworks.Security
      ];

      configurePhase = attrs.configurePhase or ''
        runHook preConfigure
        export CARGO_HOME=$NIX_BUILD_TOP
        export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix $NIX_BUILD_TOP=build-root"
        runHook postConfigure
      '';

      buildPhase = attrs.buildPhase or ''
        runHook preBuild
        cargo build --release ${getFeatures buildFeatures}
        runHook postBuild
      '';

      checkPhase = attrs.checkPhase or ''
        cargo fmt -- --check
        cargo test ${getFeatures testFeatures} --release
        cargo clippy ${getFeatures testFeatures}
        ${extraChecks}
      '';

      preFixup = ''
        # The binary we built will be full of paths pointing to the nix store.
        # Nix thinks it is doing us a favour by automatically adding dependencies
        # by finding store paths in the binary. We strip these store paths so
        # Nix won't find them.
        find $out -type f -exec remove-references-to -t ${vendor} '{}' +
        find $out -type f -exec remove-references-to -t ${rustBin} '{}' +
      '';

      targetSetup = base.mkTargetSetup {
        name = attrs.targetSetup.name or "rust";
        markerFiles = attrs.targetSetup.markerFiles or [ ] ++ [ "Cargo.toml" ];
        # Right now we only have .gitignore in here because of
        # https://github.com/rust-lang/cargo/issues/6357
        # but this means that we can add other files as well if we want to
        templateDir = pkgs.symlinkJoin {
          name = "rust-component-template";
          paths = (
            pkgs.lib.optional (attrs ? targetSetup.templateDir) attrs.targetSetup.templateDir
          ) ++ [ ./component-template ];
        };
        showTemplate = attrs.targetSetup.showTemplate or false;
        variables =
          let
            cfg = base.parseConfig {
              key = "components";
              structure = {
                author = null;
                email = null;
              };
            };
          in
          ({
            cargoLock = if filterCargoLock then "Cargo.lock" else "#Cargo.lock";
            CARGO_NAME = cfg.author;
            CARGO_EMAIL = cfg.email;
          } // attrs.targetSetup.variables or { });
        initCommands = ''cargo init
        ${attrs.targetSetup.initCommands or ""}'';
      };

      shellHook = ''
        runHook preShell
        export RUST_SRC_PATH=${rustSrcNoSymlinks}
        ${cargoAlias}
        ${commands}
        ${shellHook}
        runHook postShell
      '';

      CARGO_BUILD_TARGET = hostTriple;

    } // (
      let
        flagList = lib.optional (attrs ? RUSTFLAGS) attrs.RUSTFLAGS
        ++ lib.optional warningsAsErrors "-D warnings"
        ++ lib.optional (stdenv.hostPlatform.isWasi) "-Clinker-flavor=gcc";
      in
      lib.optionalAttrs (flagList != [ ]) {
        RUSTFLAGS = builtins.concatStringsSep " " flagList;
      }
    ) // (
      if hostTriple != buildTriple then
        let
          hostTripleEnvVar = lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] hostTriple);
          buildTripleEnvVar = lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] buildTriple);
        in
        {
          # cross-things
          "CARGO_TARGET_${hostTripleEnvVar}_LINKER" = "${linkerForHost}";
          "CC_${hostTripleEnvVar}" = "${ccForHost}";
          "CXX_${hostTripleEnvVar}" = "${cxxForHost}";

          "CARGO_TARGET_${buildTripleEnvVar}_LINKER" = "${linkerForBuild}";
          "CC_${buildTripleEnvVar}" = "${ccForBuild}";
          "CXX_${buildTripleEnvVar}" = "${cxxForBuild}";
        } else { }
    )
  )
