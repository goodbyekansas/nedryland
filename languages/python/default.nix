{ base, pkgs }:
rec {
  mkPackage = import ./package.nix pkgs base;
  mkUtility =
    { name
    , version
    , src
    , pythonVersion
    , checkInputs ? (pythonPkgs: [ ])
    , buildInputs ? (pythonPkgs: [ ])
    , nativeBuildInputs ? (pythonPkgs: [ ])
    , propagatedBuildInputs ? (pythonPkgs: [ ])
    , preBuild ? ""
    , doStandardTests ? true
    }:
    let
      package = mkPackage { inherit name version pythonVersion checkInputs buildInputs nativeBuildInputs propagatedBuildInputs preBuild src doStandardTests; };

      packageWithWheel = package // {
        wheel = pythonVersion.pkgs.buildPythonPackage {
          pname = "${name}-wheel";
          format = "other";

          inherit src;

          buildPhase = ''
            ${pythonVersion} setup.py bdist_wheel
          '';

          installPhase = ''
            mkdir -p $out
            cp dist/*.whl $out/
          '';
        };
      };
    in
    base.mkComponent {
      package = packageWithWheel;
    };
}
