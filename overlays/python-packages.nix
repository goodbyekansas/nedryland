_: pkgs:
let
  pythonVersions = [
    {
      pkg = pkgs.python39;
      attr = "python39";
    }
    {
      pkg = pkgs.python38;
      attr = "python38";
    }
    {
      pkg = pkgs.python37;
      attr = "python37";
    }
  ];
in
(builtins.foldl'
  (combined: pythonVersion:
    (combined // {
      # pkgs.<python-version>.pkgs
      "${pythonVersion.attr}" = pythonVersion.pkg.override {
        packageOverrides = _: import ./python-packages-common.nix pkgs;
      };

      # pkgs.<python-version>Packages
      "${pythonVersion.attr}Packages" = pythonVersion.pkg.pkgs;
    })
  )
  { }
  pythonVersions
)
