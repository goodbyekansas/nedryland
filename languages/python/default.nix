{ base, pkgs }:
rec {
  mkPackage = import ./package.nix pkgs base wheelHook;

  mkDocs = import ./docs.nix base pkgs.lib;

  # setup hook that creates a "link" file in the
  # derivation that depends on this wheel derivation
  wheelHook = pkgs.makeSetupHook { name = "copyWheelHook"; } ./wheelHook.bash;

  fromProtobuf = { name, version, protoSources, protoInputs, pythonVersion ? pkgs.python3 }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit base name version protoSources protoInputs; };
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
    , checkInputs ? (_: [ ])
    , buildInputs ? (_: [ ])
    , nativeBuildInputs ? (_: [ ])
    , propagatedBuildInputs ? (_: [ ])
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
    in
    base.mkLibrary {
      inherit name package;
      python = package;
      docs = (mkDocs attrs) // attrs.docs or { };
    };

  mkClient =
    attrs@{ name
    , version
    , src
    , pythonVersion
    , checkInputs ? (_: [ ])
    , buildInputs ? (_: [ ])
    , nativeBuildInputs ? (_: [ ])
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
      docs = (mkDocs attrs) // attrs.docs or { };
      package = application;
      python = application;
    };

  mkService =
    attrs@{ name
    , version
    , src
    , pythonVersion
    , checkInputs ? (_: [ ])
    , buildInputs ? (_: [ ])
    , nativeBuildInputs ? (_: [ ])
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
      docs = (mkDocs attrs) // attrs.docs or { };
      package = application;
      python = application;
    };
}
