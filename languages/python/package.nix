pkgs: base: attrs_@{ name
            , version
            , src
            , pythonVersion
            , srcExclude ? [ ]
            , preBuild ? ""
            , format ? "setuptools"
            , setuptoolsLibrary ? false
            , doStandardTests ? true
            , ...
            }:
let
  pythonPkgs = pythonVersion.pkgs;
  invariantSrc = if pkgs.lib.isStorePath src then src else
  (builtins.path {
    inherit name;
    path = src;
    filter = (path: type: !(builtins.any (pred: pred path type) srcExclude));
  });
  commands = ''
    check() {
        eval "$installCheckPhase"
    }
  '';

  extendFile = { src, filePath, baseFile, name }:
    pkgs.stdenv.mkDerivation {
      inherit filePath;
      src = invariantSrc;
      name = "pyconfig-${builtins.baseNameOf filePath}";
      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out/$(dirname $filePath)

        if [ ! -f $src/$filePath ] || [ -L $src/$filePath ]; then
            echo "Using default \"$filePath\" because there is no \"$filePath\" in the source, or it is generated"
            cp ${baseFile} $out/$filePath
            chmod +w $out/$filePath

            if [ -f $src/$filePath.include ]; then
               echo "Including \"$filePath.include\" in \"$filePath\""
               echo "" >> $out/$filePath
               echo "# from ${name}'s $filePath.include" >> $out/$filePath
               cat $src/$filePath.include >> $out/$filePath
            fi
            chmod -w $out/$filePath
        else
            echo "Using ${name}'s $filePath since it exists in the source and is not generated"
            cp $src/$filePath $out/$filePath
        fi
      '';
    };

  setupCfg = ''${extendFile {
      filePath = "setup.cfg";
      baseFile = ./setup.cfg;
      inherit name;
      src = invariantSrc;
      }}/setup.cfg'';

  pylintrc = ''
    ${extendFile {
      filePath = "pylintrc";
      baseFile = ./pylintrc;
      inherit name;
      src = invariantSrc;
      }}/pylintrc
  '';

  standardTests = (
    if doStandardTests then {
      checkPhase = ''
        echo "Running pytest (with pylint, flake8, mypy, isort and black) 🧪"
        pytest --pylint --black --mypy --flake8 --isort ./
      '';
    } else { }
  );
  mypyHook = pkgs.makeSetupHook
    {
      name = "mypy-hook";
      substitutions = {
        "sitePackages" = pythonVersion.sitePackages;
      };
    }
    ./mypy-hook.sh;
  attrs = builtins.removeAttrs attrs_ [ "srcExclude" "shellInputs" "targetSetup" ];
in
pythonPkgs.buildPythonPackage (attrs // {
  inherit version setupCfg pylintrc format preBuild;
  pname = name;
  src = invariantSrc;

  # Dependencies needed for running the checkPhase. These are added to nativeBuildInputs when doCheck = true. Items listed in tests_require go here.
  checkInputs = with pythonPkgs; [
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

    python-language-server
    pyls-mypy
    pyls-isort
  ] ++ attrs.checkInputs or (x: [ ]) pythonPkgs;

  # Build and/or run-time dependencies that need to be be compiled
  # for the host machine. Typically non-Python libraries which are being linked.
  buildInputs = attrs.buildInputs or (x: [ ]) pythonPkgs;

  # Build-time only dependencies. Typically executables as well
  # as the items listed in setup_requires
  nativeBuildInputs = attrs.nativeBuildInputs or (x: [ ]) pythonPkgs
    ++ [ mypyHook ];

  passthru = { shellInputs = (attrs_.shellInputs or [ ]); };

  # Aside from propagating dependencies, buildPythonPackage also injects
  # code into and wraps executables with the paths included in this list.
  # Items listed in install_requires go here
  propagatedBuildInputs = attrs.propagatedBuildInputs or (x: [ ]) pythonPkgs;

  doCheck = false;

  configurePhase = ''
    rm -f setup.cfg
    rm -f .pylintrc
    ln -s $setupCfg setup.cfg
    ln -s $pylintrc .pylintrc
  '';

  targetSetup = base.mkTargetSetup {
    name = "python";
    markerFiles = attrs_.targetSetup.markerFiles or [ ] ++ [ "setup.py" ];
    templateDir = pkgs.symlinkJoin {
      name = "python-component-template";
      paths = (
        pkgs.lib.optional (attrs_ ? targetSetup.templateDir) attrs_.targetSetup.templateDir
      ) ++ [ ./component-template ];
    };
    variables = ({
      inherit version;
      pname = name;
      mainPackage = attrs_.targetSetup.mainPackage or (pkgs.lib.toLower (builtins.replaceStrings [ "-" " " ] [ "_" "_" ] name));
      entryPoint = if setuptoolsLibrary then "" else "\\\"${name}=${name}.main:main\\\"";
    } // attrs_.targetSetup.variables or { });
    variableQueries = ({
      desc = "✍️ Write a short description for your function";
      author = "🤓 Enter author name:";
      email = "📧 Enter author email:";
      url = "🏄 Enter author website url:";
    } // attrs_.targetSetup.variableQueries or { });
  };

  shellHook = ''
    if [ -L setup.cfg ]; then
       unlink setup.cfg
    fi

    if [ ! -f setup.cfg ]; then
       ln -s $setupCfg setup.cfg
    fi

    if [ -L .pylintrc ]; then
       unlink .pylintrc
    fi

    if [ ! -f .pylintrc ]; then
       ln -s $pylintrc .pylintrc
    fi
    ${commands}
    ${attrs.shellHook or ""}
  '';

  postFixup = ''
    ${attrs.postFixup or ""}
    mkdir -p $out/nedryland
    touch $out/nedryland/add-to-mypy-path
  '';
} // standardTests)
