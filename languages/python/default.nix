{ base, pkgs, lib, callPackage }:
let
  defaultPythonVersion = pkgs."${(base.parseConfig {
    key = "python";
    structure = {
      version = "python3";
    };
  }).version}";

  inherit (import ./utils.nix base) resolveInputs;

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
      package =
        let
          pkg = postPackageFunc (mkPackage (attrs // {
            checkInputs = (py: attrs.checkInputs or (_: [ ]) py ++ [ (hooks.check py) ]);
            nativeBuildInputs = (py: attrs.nativeBuildInputs or (_: [ ]) py ++ [ (hooks.mypy py.python) ]);
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
    let
      generatedCode = callPackage ./protobuf.nix { inherit base name version protoSources protoInputs; };
    in
    mkLibrary {
      inherit version pythonVersion;
      name = "${name}-python-protobuf";
      src = generatedCode;
      propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ] ++ builtins.map (pi: pi.python.package) protoInputs);
      doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
    };

  mkComponent = mkComponentWith base.mkComponent (x: x);

  mkLibrary = attrs: mkComponentWith base.mkLibrary (x: x) (attrs // { setuptoolsLibrary = true; });

  mkClient = attrs: mkComponentWith base.mkClient (attrs.pythonVersion or defaultPythonVersion).pkgs.toPythonApplication attrs;

  mkService = attrs: mkComponentWith base.mkService (attrs.pythonVersion or defaultPythonVersion).pkgs.toPythonApplication attrs;
}
