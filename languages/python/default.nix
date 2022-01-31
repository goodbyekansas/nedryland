{ base, lib, python3, callPackage }:
let
  hooks = callPackage ./hooks { };

  mkPackage = callPackage ./package.nix { inherit base; };

  mkDocs = callPackage ./docs.nix { inherit base; };

  mkComponentWith = componentFunc: postPackageFunc: attrs:
    let
      # We only want to build a wheel if we are using a format for wheels. Also skip the
      # wheel if we don't have the config file, else the shell won't work for new
      # components, since the shell goes to the package which depends on the wheel being
      # built. And it is the shell's responsibility to run the targetSetup which
      # provides the interactive initialization of the component.
      buildWheel = (attrs.format or "setuptools" == "setuptools" && builtins.pathExists (attrs.src + /setup.py))
        || (builtins.elem (attrs.format or "setuptools") [ "flit" "pyproject" ] && builtins.pathExists (attrs.src + /pyproject.toml));

      wheel = mkPackage (attrs // {
        name = "${attrs.name}-wheel";
        nativeBuildInputs = (py: attrs.nativeBuildInputs or (_: [ ]) py ++ [ hooks.wheel ]);
        doStandardTests = false; # tests are run on the package (the installed wheel)
        dontUseSetuptoolsCheck = true;
        dontUsePipInstall = true; # we want to keep the wheel
      });

      pkgAttrs = attrs // {
        checkInputs = (py: attrs.checkInputs or (_: [ ]) py ++ [ (hooks.check py) ]);
        nativeBuildInputs = (py: attrs.nativeBuildInputs or (_: [ ]) py ++ [ (hooks.mypy py.python) ]);
      } // lib.optionalAttrs buildWheel {
        # Use wheel format to install the wheel, that workflow makes pytest weird so
        # keeping the same src and unpack for that.
        dontUseWheelUnpack = true;
        inherit wheel;
        buildPhase = ''
          mkdir -p dist
          cp $wheel/*.whl dist
        '';
        format = "wheel";
      };

      package = postPackageFunc (mkPackage pkgAttrs);
    in
    componentFunc ({
      inherit (attrs) name version;
      inherit package;
      docs = (mkDocs attrs) // attrs.docs or { };
      python = package;
    } // lib.optionalAttrs buildWheel { inherit wheel; });
in
rec {
  inherit mkDocs hooks;

  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? python3 }:
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

  mkClient = attrs: mkComponentWith base.mkClient attrs.pythonVersion.pkgs.toPythonApplication attrs;

  mkService = attrs: mkComponentWith base.mkService attrs.pythonVersion.pkgs.toPythonApplication attrs;
}
