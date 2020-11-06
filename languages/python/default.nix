{ base, pkgs }:
rec {
  mkPackage = import ./package.nix pkgs base;
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
}
