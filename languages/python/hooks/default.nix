{ makeSetupHook, writeScriptBin, runCommandLocal, python310, bat }:
let
  mergeConfigs = src: name: key: files: runCommandLocal name { } ''
    export PYTHONPATH=''${PYTHONPATH:-}:${python310.pkgs.toml}/${python310.sitePackages}
    ${python310}/bin/python ${./config-merger.py} "${key}" ${builtins.concatStringsSep " " (
      builtins.map (file:
        if builtins.isPath file.path then
          "${file.path}=${file.key}"
        else
          "${src}/${file.path}=${file.key}"
      ) 
      (
        builtins.filter
          (file: if builtins.isPath file.path then true else builtins.pathExists (src + "/${file.path}"))
          (
            builtins.map
              (path: if builtins.isAttrs path then path else {inherit key path;})
              files
          )
      )
    )}
  '';

  generateConfigurationRunner =
    { toolDerivation
    , toolName ? toolDerivation.pname or toolDerivation.name
    , configFlag ? "--config"
    , config
    , configFlagAfter ? false
    , extraArgs ? ""
    }:
    writeScriptBin toolName ''
      if [[ $@ =~ "--print-generated-config-path" ]]; then
        echo "${config}"
        exit 0
      fi

      if [[ $@ =~ "--print-generated-config" ]]; then
        ${bat}/bin/bat "${config}"
        exit 0
      fi

      ${toolDerivation}/bin/${toolName} ${
        if configFlagAfter then
          "\"$@\" ${configFlag} ${config} ${extraArgs}"
        else
          "${configFlag} ${config} \"$@\" ${extraArgs}"}
    '';

  blackWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    config = mergeConfigs src "black.toml" "black" [
      { path = "pyproject.toml"; key = "tool.black"; }
      "setup.cfg"
      { path = ./config/black.toml; key = "tool.black"; }
    ];
  };

  coverageWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    configFlag = "--rcfile";
    configFlagAfter = true;
    config = mergeConfigs src "coverage.toml" "coverage" [
      ".coveragerc"
      { path = "setup.cfg"; key = "tool:coverage"; }
      { path = "tox.ini"; key = "tool:coverage"; }
      { path = "pyproject.toml"; key = "tool.coverage"; }
      { path = ./config/coverage.toml; key = "tool.coverage"; }
    ];
  };

  flake8WithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    config = mergeConfigs src "flake8.ini" "flake8" [
      ".flake8"
      "setup.cfg"
      "tox.ini"
      { path = ./config/flake8.toml; key = "tool.pycodestyle"; }
      { path = ./config/flake8.toml; key = "tool.flake8"; }
    ];
  };

  isortWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    configFlag = "--settings-file";
    extraArgs = "--src-path .";
    config = mergeConfigs src "isort.ini" "isort" [
      ".isort.cfg"
      { path = "pyproject.toml"; key = "tool.isort"; }
      "setup.cfg"
      "tox.ini"
      ".editorconfig"
      { path = ./config/isort.toml; key = "tool.isort"; }
    ];
  };

  mypyWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    configFlag = "--config-file";
    config = mergeConfigs src "mypy.ini" "mypy" [
      "mypy.ini"
      ".mypy.ini"
      { path = "pyproject.toml"; key = "tool.mypy"; }
      "setup.cfg"
      { path = ./config/mypy.toml; key = "tool.mypy"; }
    ];
  };

  pylintWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    configFlag = "--rcfile";
    config = mergeConfigs src "pylint.toml" "pylint" [
      { path = "pylintrc"; key = ""; }
      { path = ".pylintrc"; key = ""; }
      { path = "pyproject.toml"; key = "tool.pylint"; }
      { path = ./config/pylint.toml; key = "tool.pylint"; }
    ];
  };

  pytestWithConfig = src: toolDerivation: generateConfigurationRunner {
    inherit toolDerivation;
    configFlag = "-c";
    config = mergeConfigs src "pytest.ini" "pytest" [
      "pytest.ini"
      { path = "pyproject.toml"; key = "tool.pytest.ini_options"; }
      { path = "pylintrc.toml"; key = "tool.pytest.ini_options"; }
      "tox.ini"
      { path = "setup.cfg"; key = "tool:pytest"; }
      { path = ./config/pytest.toml; key = "tool.pytest.ini_options"; }
    ];
    extraArgs = "--rootdir=./";
  };
in
{
  wheelList = makeSetupHook { name = "wheel-list-hook"; } ./wheel-list.bash;

  check = src: pythonPkgs:
    makeSetupHook
      {
        name = "check-hook";
        deps = with pythonPkgs; [
          (blackWithConfig src black)
          (coverageWithConfig src coverage)
          (flake8WithConfig src flake8)
          (isortWithConfig src isort)
          (mypyWithConfig src mypy)
          (pylintWithConfig src pylint)

          (pytestWithConfig src pytest)
          pytest-pylint
          pytest-black
          pytest-mypy
          (pytest-flake8.overrideAttrs (pyt: {
            patches = pyt.patches or [ ] ++ [ ./flake8-config-arg.patch ];
          }))
          (pytest-isort.overrideAttrs (pis: {
            patches = pis.patches or [ ] ++ [ ./isort-config-arg.patch ];
          }))
          pytest-cov
        ];
      } ./check.bash;
}
