{ pkgs
, base
, stdenv
, buildPackages
, rustVersion
, rust # use this for toRustTarget
}:

attrs@{ name
, src
, srcExclude ? [ ]
, extensions ? [ ]
, targets ? [ ]
, defaultTarget ? ""
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
  # this controls the version of rust to use
  rustBin = (
    if useNightly != "" then
      (
        pkgs.rust-bin.nightly."${useNightly}".rust.override {
          inherit targets extensions;
        }
      )
    else
      (
        pkgs.rust-bin.stable."${rustVersion}".rust.override {
          inherit targets extensions;
        }
      )
  );

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

  invariantSource =
    if !(pkgs.lib.isStorePath src) then
      (builtins.path {
        path = src;
        inherit name;
        filter =
          (
            path: type: !(type == "directory" && baseNameOf path == "target")
              && !(type == "directory" && baseNameOf path == ".cargo")
              && !(filterCargoLock && type == "regular" && baseNameOf path == "Cargo.lock")
              && !(builtins.any (pred: pred path type) srcExclude)
          );
      }) else src;

  vendor = import ./vendor.nix pkgs rustBin {
    inherit name;
    buildInputs = attrs.buildInputs or [ ];
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

  safeAttrs = builtins.removeAttrs attrs [ "extraChecks" "testFeatures" "buildFeatures" "srcExclude" "shellInputs" ];

  # cross compiling
  ccForBuild = "${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}cc";
  cxxForBuild = "${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}c++";
  ccForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc";
  cxxForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}c++";

  hostTriple = builtins.replaceStrings [ "wasm32-unknown-wasi" "-" ] [ "wasm32_wasi" "_" ] (rust.toRustTarget stdenv.hostPlatform);
  buildTriple = builtins.replaceStrings [ "wasm32-unknown-wasi" "-" ] [ "wasm32_wasi" "_" ] (rust.toRustTarget stdenv.buildPlatform);

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
        hostPlatform = defaultTarget;
        buildPlatform = stdenv.buildPlatform;
      })))
    )
    { }
    runners;

in
stdenv.mkDerivation
  (
    safeAttrs // {
      inherit name;
      strictDeps = true;
      disallowedReferences = [ vendor ];
      src = invariantSource;

      nativeBuildInputs = with pkgs; [
        cacert
        rustBin
        removeReferencesTo
      ] ++ attrs.nativeBuildInputs or [ ]
      ++ (pkgs.lib.lists.optionals (defaultTarget == "wasm32-wasi") [ pkgs.wasmer-with-run ])
      ++ [ vendor ];

      passthru = { shellInputs = (attrs.shellInputs or [ ] ++ [ rustSrcNoSymlinks ]); };

      depsBuildBuild = [ buildPackages.stdenv.cc ]
      ++ pkgs.lib.optionals stdenv.buildPlatform.isDarwin [
        # this is needed since https://github.com/rust-lang/libc/commit/3e4d684dcdd1dff363a45c70c914204013810155
        # on macos
        buildPackages.libiconv

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

      installPhase = attrs.installPhase or ''
        mkdir -p $out
      '';

      preFixup = ''
        # The binary we built will be full of paths pointing to the nix store.
        # Nix thinks it is doing us a favour by automatically adding dependencies
        # by finding store paths in the binary. We strip these store paths so
        # Nix won't find them.
        find $out -type f -exec remove-references-to -t ${vendor} '{}' +
        find $out -type f -exec remove-references-to -t ${rustBin} '{}' +
      '';

      shellHook = ''
        runHook preShell
        export RUST_SRC_PATH=${rustSrcNoSymlinks}
        ${cargoAlias}
        ${commands}
        ${shellHook}
        runHook postShell
      '';

    } // (
      if defaultTarget != "" then {
        CARGO_BUILD_TARGET = defaultTarget;
      } else { }
    ) // runnerAttrs // (
      let
        flagList = pkgs.lib.optional (attrs ? RUSTFLAGS) attrs.RUSTFLAGS
        ++ pkgs.lib.optional warningsAsErrors "-D warnings"
        ++ pkgs.lib.optional (hostTriple == "wasm32_wasi") "-Clinker-flavor=gcc";
      in
      if flagList != [ ] then {
        RUSTFLAGS = builtins.concatStringsSep " " flagList;
      } else { }
    ) // (
      if hostTriple != buildTriple then {
        # cross-things
        "CARGO_TARGET_${stdenv.lib.toUpper hostTriple}_LINKER" = "${ccForHost}";
        "CC_${stdenv.lib.toUpper hostTriple}" = "${ccForHost}";
        "CXX_${stdenv.lib.toUpper hostTriple}" = "${cxxForHost}";

        "CARGO_TARGET_${stdenv.lib.toUpper buildTriple}_LINKER" = "${ccForBuild}";
        "CC_${stdenv.lib.toUpper buildTriple}" = "${ccForBuild}";
        "CXX_${stdenv.lib.toUpper buildTriple}" = "${cxxForBuild}";
      } else { }
    )
  )
