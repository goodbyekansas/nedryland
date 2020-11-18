{ base, pkgs }:
rec {
  mkPackage = import ./package.nix pkgs base;
  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? pkgs.python3 }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit name version protoSources protoInputs; };
    in
    mkUtility {
      inherit name version pythonVersion;
      src = generatedCode;
      propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ] ++ builtins.map (pi: pi.python.package) protoInputs);
      doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
    };
  mkUtility =
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
      });

      # setup hook that creates a "link" file in the
      # derivation that depends on this wheel derivation
      wheel = pkgs.makeSetupHook { name = "copyWheelHook"; } ./wheelHook.sh;
      packageWithWheel = package.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [ wheel ];
      });
    in
    base.mkComponent {
      package = packageWithWheel;
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
      package = application;
    };
}
