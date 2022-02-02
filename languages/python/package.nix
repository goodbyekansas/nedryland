pkgs: base: wheelHook: attrs_@{ name
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
  resolveInputs = (import ./utils.nix).resolveInputs pythonPkgs;

  customerFilter = src:
    let
      # IMPORTANT: use a let binding like this to memoize info about the git directories.
      srcIgnored = pkgs.gitignoreFilter src;
    in
    path: type:
      (srcIgnored path type) && !(builtins.any (pred: pred path type) srcExclude);
  filteredSrc =
    if srcExclude != [ ] && attrs_ ? src then
      pkgs.lib.cleanSourceWith
        {
          inherit (attrs_) src;
          filter = customerFilter attrs_.src;
          name = "${name}-source";
        } else pkgs.gitignoreSource attrs_.src;
  src = if pkgs.lib.isStorePath attrs_.src then attrs_.src else filteredSrc;

  commands = ''
    check() {
        eval "$installCheckPhase"
    }
  '';

  extendFile = { filePath, baseFile, name }:
    pkgs.stdenv.mkDerivation {
      inherit filePath src;
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
      }}/setup.cfg'';

  pylintrc = ''
    ${extendFile {
      filePath = "pylintrc";
      baseFile = ./pylintrc;
      inherit name;
      }}/pylintrc
  '';

  standardTests = {
    checkPhase = if (attrs ? checkPhase) then attrs.checkPhase else
    (
      if doStandardTests then
        ''
          echo "Running pytest (with pylint, flake8, mypy, isort and black) 🧪"
          pytest --pylint --black --mypy --flake8 --isort ./
        ''
      else ""
    );
  };

  mypyHook = pkgs.makeSetupHook
    {
      name = "mypy-hook";
      substitutions = {
        "sitePackages" = pythonVersion.sitePackages;
      };
    }
    ./mypy-hook.sh;
  attrs = builtins.removeAttrs attrs_ [ "srcExclude" "shellInputs" "targetSetup" "docs" ];

in
pythonPkgs.buildPythonPackage (attrs // {
  inherit src version setupCfg pylintrc format preBuild;
  pname = name;

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
  ] ++ (resolveInputs attrs.checkInputs or (_: [ ]));

  # Build and/or run-time dependencies that need to be be compiled
  # for the host machine. Typically non-Python libraries which are being linked.
  buildInputs = (resolveInputs attrs.buildInputs or (_: [ ])) ++ pkgs.lib.optional (format == "setuptools") wheelHook;

  # Build-time only dependencies. Typically executables as well
  # as the items listed in setup_requires
  nativeBuildInputs = (resolveInputs attrs.nativeBuildInputs or (_: [ ]))
    ++ [ mypyHook ];

  passthru = { shellInputs = (resolveInputs attrs_.shellInputs or (_: [ ])); };

  # Aside from propagating dependencies, buildPythonPackage also injects
  # code into and wraps executables with the paths included in this list.
  # Items listed in install_requires go here
  propagatedBuildInputs = resolveInputs attrs.propagatedBuildInputs or (_: [ ]);

  doCheck = false;

  configurePhase = attrs.configurePhase or ''
    rm -f setup.cfg
    rm -f .pylintrc
    ln -s $setupCfg setup.cfg
    ln -s $pylintrc .pylintrc
  '';

  targetSetup = base.mkTargetSetup {
    name = attrs_.targetSetup.name or "python";
    markerFiles = attrs_.targetSetup.markerFiles or [ ] ++ [ "setup.py" ];
    templateDir = pkgs.symlinkJoin {
      name = "python-component-template";
      paths = (
        pkgs.lib.optional (attrs_ ? targetSetup.templateDir) attrs_.targetSetup.templateDir
      ) ++ [ ./component-template ];
    };
    variables = (rec {
      inherit version;
      pname = name;
      mainPackage = pkgs.lib.toLower (builtins.replaceStrings [ "-" " " ] [ "_" "_" ] name);
      entryPoint = if setuptoolsLibrary then "{}" else "{\\\"console_scripts\\\": [\\\"${name}=${mainPackage}.main:main\\\"]}";
    } // attrs_.targetSetup.variables or { });
    variableQueries = ({
      desc = "✍️ Write a short description for your function";
      author = "🤓 Enter author name:";
      email = "📧 Enter author email:";
      url = "🏄 Enter author website url:";
    } // attrs_.targetSetup.variableQueries or { });
    initCommands = "black .";
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
