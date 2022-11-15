{ base, pkgs, lib, callPackage }:
let
  defaultPythonVersion = pkgs."${(base.parseConfig {
    key = "python";
    structure = {
      version = "python3";
    };
  }).version}";

  hooks = callPackage ./hooks { };

  mkPackage = callPackage ./package.nix { inherit base defaultPythonVersion; };

  mkDocs = callPackage ./docs.nix { inherit base defaultPythonVersion; };

  addWheelOutput = pythonPackage:
    pythonPackage.overrideAttrs (packageAttrs:
      {
        outputs = pythonPackage.outputs or [ "out" ] ++ [ "wheel" ];
        postInstall = ''
          ${pythonPackage.postInstall or ""}
          mkdir -p "$wheel"
          cp dist/*.whl "$wheel"
        '';
        nativeBuildInputs = packageAttrs.nativeBuildInputs or [ ] ++ [ hooks.wheelList ];
      }
    );

  mkComponentWith = componentFunc: postPackageFunc: attrs:
    let
      # Only build wheel if we have a format that builds a wheel. Duh.
      buildWheel = builtins.elem (attrs.format or "setuptools") [ "setuptools" "flit" "pyproject" ];
      pyPkgs = (attrs.pythonVersion or defaultPythonVersion).pkgs;
      resolveInputs = (import ./utils.nix base).resolveInputs pyPkgs attrs.name;
      package =
        let
          pkg = postPackageFunc (mkPackage (attrs // {
            # Dependencies needed for running the checkPhase. These are added to nativeBuildInputs when doCheck = true.
            # Items listed in tests_require go here.
            checkInputs = (
              resolveInputs "checkInputs" attrs.checkInputs or [ ]
            )
            ++ [ (hooks.check pyPkgs) ]
            ++ (builtins.map (input: pyPkgs."types-${input.pname or input.name}" or null) (builtins.filter lib.isDerivation propagatedBuildInputs))
            ++ (lib.optional (attrs.format or "setuptools" == "setuptools") pyPkgs.types-setuptools);

            # Build-time only dependencies. Typically executables as well
            # as the items listed in setup_requires
            nativeBuildInputs = (
              resolveInputs "nativeBuildInputs" attrs.nativeBuildInputs or [ ]
            );

            # Don't install dependencies with pip, let nix handle that
            preInstall = ''
              pipInstallFlags+=('--no-deps')
            '';
          }));
        in
        if buildWheel then addWheelOutput pkg else pkg;

    in
    componentFunc ({
      inherit (attrs) name version;
      inherit package;
      docs = (mkDocs attrs) // attrs.docs or { };
      python = package;
    } // lib.optionalAttrs buildWheel { wheel = package.wheel; });
in
rec {
  inherit mkDocs addWheelOutput hooks;

  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? defaultPythonVersion }:
    (mkLibrary
      {
        inherit version pythonVersion;
        name = "${name}-python-protobuf";
        src = callPackage ./protobuf.nix { inherit base name version protoSources protoInputs; };
        propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ] ++ builtins.map (pi: pi.python.package) protoInputs);
        doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
      } // {
      __functor = self: { author, email }: self.overrideAttrs (_: {
        src = callPackage ./protobuf.nix { inherit base name version protoSources protoInputs author email; };
      });
    });

  mkComponent = mkComponentWith base.mkComponent (x: x);

  mkLibrary = attrs: mkComponentWith base.mkLibrary (x: x) (attrs // { setuptoolsLibrary = true; });

  mkClient = attrs: mkComponentWith base.mkClient (attrs.pythonVersion or defaultPythonVersion).pkgs.toPythonApplication attrs;

  mkService = attrs: mkComponentWith base.mkService (attrs.pythonVersion or defaultPythonVersion).pkgs.toPythonApplication attrs;
}
