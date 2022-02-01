{ pkgs
, base
, stdenv
, lib
, buildPackages
, rustVersion
, toRustTarget
}:

attrs@{ name
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

  vendor = import ./vendor.nix pkgs rustBin {
    inherit name;
    buildInputs = attrs.buildInputs or [ ];
    extraCargoConfig = attrs.extraCargoConfig or "";
    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];
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

  safeAttrs = builtins.removeAttrs attrs [ "extraChecks" "testFeatures" "buildFeatures" "srcExclude" "shellInputs" "docs" ];

  # cross compiling
  ccForBuild = "${buildPackages.stdenv.cc.targetPrefix}cc";
  cxxForBuild = "${buildPackages.stdenv.cc.targetPrefix}c++";
  linkerForBuild = ccForBuild;

  ccForHost = "${stdenv.cc.targetPrefix}cc";
  cxxForHost = "${stdenv.cc.targetPrefix}c++";
  # after https://github.com/rust-lang/rust/commit/6615ee89be2290c96aa7d4ab24dc94e23a8c7080
  # `--as-needed` is wrongfully added to wasm-ld even though it isn't a GNU linker
  # workaround it by removing the argument before passing along
  # this can safely be removed when that is fixed
  # https://github.com/rust-lang/rust/pull/85920
  linkerForHost =
    if stdenv.hostPlatform.isWasi then "${(pkgs.writeScriptBin "rust-linker-bug-workaround" ''
    #!${pkgs.bash}/bin/bash
    for param in "$@"; do
      [[ ! $param == '-Wl,--as-needed' ]] && newparams+=("$param")
    done
    set -- "''${newparams[@]}"
    ${ccForHost} "''${newparams[@]}"
  '')}/bin/rust-linker-bug-workaround" else ccForHost;

  runners = [
    ./runner/wasi.nix
    ./runner/windows.nix
  ];

  runnerAttrs = builtins.foldl'
    (acc: curr:
      let
        function = import curr;
        args = builtins.functionArgs function;
      in
      (acc // (function ((builtins.intersectAttrs args pkgs) // {
        inherit attrs;
        hostPlatform = stdenv.hostPlatform;
        buildPlatform = stdenv.buildPlatform;
      })))
    )
    { }
    runners;

in
base.mkDerivation
  (
    safeAttrs // {
      inherit stdenv;
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
      ] ++ attrs.nativeBuildInputs or [ ]
      ++ (pkgs.lib.lists.optionals (stdenv.hostPlatform.isWasi) [ pkgs.wasmer ])
      ++ [ vendor ];

      passthru = { shellInputs = (attrs.shellInputs or [ ] ++ [ rustSrcNoSymlinks rustAnalyzer ]); };

      depsBuildBuild = pkgs.lib.optionals stdenv.buildPlatform.isDarwin [
        # this is actually not always needed but life is
        # too short to figure out when so let's always
        # add it
        buildPackages.darwin.apple_sdk.frameworks.Security
      ];

      buildInputs = attrs.buildInputs or [ ];
      propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];

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

    } // runnerAttrs // (
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
