{ base, pkgs, versions }:
rec {
  mkPackage = import ./package.nix pkgs base;

  mkDocs = import ./docs.nix pkgs base.parseConfig;

  # setup hook that creates a "link" file in the
  # derivation that depends on this wheel derivation
  wheelHook = pkgs.makeSetupHook { name = "copyWheelHook"; } ./wheelHook.sh;

  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? pkgs.python3 }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit name version protoSources protoInputs; };
    in
    mkLibrary {
      inherit version pythonVersion;
      name = "${name}-python-protobuf";
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

      packageWithWheel = package.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [ wheelHook ];
      });
    in
    base.mkLibrary {
      inherit name;
      package = packageWithWheel;
      python = packageWithWheel;
      docs = mkDocs attrs;
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
    base.mkClient {
      inherit name;
      docs = mkDocs attrs;
      package = application;
      python = application;
    };

  mkService =
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
    base.mkService {
      inherit name;
      docs = mkDocs attrs;
      package = application;
      python = application;
    };
}
