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
      package = mkPackage {
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
      };

      wheel = package.overrideAttrs (oldAttrs: {
        name = "${oldAttrs.name}-wheel";
        format = "other";

        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          pythonVersion.pkgs.wheel
          pythonVersion.pkgs.pip
        ];

        # TODO: this currently builds a wheel for the host platform,
        # not the target one if that is needed. Building for the host platform
        # works well enough for python-only wheels.
        buildPhase = ''
          eval "$preBuild"
          ${oldAttrs.buildPhase or ""}
          python setup.py bdist_wheel || echo "Python utilities must support building wheels (bdist_wheel)"
          eval "$postBuild"
        '';

        installPhase = ''
          mkdir -p $out
          cp dist/*.whl $out/
        '';

        # setup hook that creates a "link" file in the
        # derivation that depends on this wheel derivation
        setupHook = ./wheelHook.sh;
      });

      packageWithWheel = package.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [ wheel ];
      });
    in
    base.mkComponent {
      package = packageWithWheel;
    };
}
