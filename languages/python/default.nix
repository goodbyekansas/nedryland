{ base, pkgs }:
rec {

  mkPackage = import ./package.nix pkgs base;

  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? pkgs.python3 }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit name version protoSources protoInputs; };
    in
    mkLibrary {
      inherit name version pythonVersion;
      src = generatedCode;
      propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ] ++ builtins.map (pi: pi.python.package) protoInputs);
      doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
    };

  mkLibrary =
    attrs@{ name
    , version
    , src
    , pythonVersion
    , checkInputs ? (pythonPkgs: [ ])
    , buildInputs ? (pythonPkgs: [ ])
    , nativeBuildInputs ? (pythonPkgs: [ ])
    , propagatedBuildInputs ? (pythonPkgs: [ ])
    , preBuild ? ""
    , doStandardTests ? true
    , ...
    }:
    let
      package = mkPackage (attrs // {
        inherit
          name
          version
          pythonVersion
          checkInputs
          buildInputs
          nativeBuildInputs
          propagatedBuildInputs
          preBuild
          src
          doStandardTests;
        setuptoolsLibrary = true;
      });

      # setup hook that creates a "link" file in the
      # derivation that depends on this wheel derivation
      wheel = pkgs.makeSetupHook { name = "copyWheelHook"; } ./wheelHook.sh;
      packageWithWheel = package.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [ wheel ];
      });
    in
    base.mkComponent {
      inherit name;
      package = packageWithWheel;
      python = packageWithWheel;
    };

  mkClient =
    attrs@{ name
    , version
    , src
    , pythonVersion
    , checkInputs ? (pythonPkgs: [ ])
    , buildInputs ? (pythonPkgs: [ ])
    , nativeBuildInputs ? (pythonPkgs: [ ])
    , preBuild ? ""
    , doStandardTests ? true
    , ...
    }:
    let
      package = mkPackage (attrs // {
        inherit
          name
          version
          pythonVersion
          checkInputs
          buildInputs
          nativeBuildInputs
          preBuild
          src
          doStandardTests;
      });
      application = pythonVersion.pkgs.toPythonApplication package;
    in
    base.mkComponent {
      inherit name;
      package = application;
      python = application;
    };
}
