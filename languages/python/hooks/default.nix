{ makeSetupHook }: {
  wheelList = makeSetupHook { name = "wheel-list-hook"; } ./wheel-list.bash;

  mypy = pythonVersion: makeSetupHook
    {
      name = "mypy-hook";
      substitutions = {
        "sitePackages" = pythonVersion.sitePackages;
      };
    }
    ./mypy-path.sh;

  check = pythonPkgs: makeSetupHook
    {
      name = "check-hook";
      deps = with pythonPkgs; [
        black
        flake8
        isort
        pylint

        pytest
        pytest-pylint
        pytest-black
        pytest-mypy
        pytest-flake8
        pytest-isort
        pytest-cov
      ];
    } ./check.bash;
}