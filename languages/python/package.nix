{ base, pkgs, lib, defaultPythonVersion }:
args@{ name
, version
, src
, pythonVersion ? defaultPythonVersion
, srcExclude ? [ ]
, preBuild ? ""
, format ? "setuptools"
, setuptoolsLibrary ? false
, doStandardTests ? true
, ...
}:
let
  pythonPkgs = pythonVersion.pkgs;
  resolveInputs = (import ./utils.nix base).resolveInputs pythonPkgs name;

  customerFilter = src:
    let
      # IMPORTANT: use a let binding like this to memoize info about the git directories.
      srcIgnored = pkgs.gitignoreFilter src;
    in
    path: type:
      (srcIgnored path type) && !(builtins.any (pred: pred path type) srcExclude);
  filteredSrc =
    if srcExclude != [ ] && args ? src then
      lib.cleanSourceWith
        {
          inherit (args) src;
          filter = customerFilter args.src;
          name = "${name}-source";
        } else pkgs.gitignoreSource args.src;
  src = if lib.isStorePath args.src then args.src else filteredSrc;

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
      filePath = ".pylintrc";
      baseFile = ./pylintrc;
      inherit name;
      }}/.pylintrc
  '';

  attrs = builtins.removeAttrs args [ "srcExclude" "shellInputs" "targetSetup" "docs" ];
in
base.enableChecks (pythonPkgs.buildPythonPackage (attrs // {
  inherit src version setupCfg pylintrc format preBuild doStandardTests;
  pname = name;

  # Build and/or run-time dependencies that need to be be compiled
  # for the host machine. Typically non-Python libraries which are being linked.
  buildInputs = resolveInputs "buildInputs" attrs.buildInputs or [ ];

  passthru = {
    shellInputs = (resolveInputs "shellInputs" args.shellInputs or [ ])
      ++ [ pythonPkgs.python-lsp-server pythonPkgs.pylsp-mypy pythonPkgs.pyls-isort ];
  };

  # Aside from propagating dependencies, buildPythonPackage also injects
  # code into and wraps executables with the paths included in this list.
  # Items listed in install_requires go here
  propagatedBuildInputs = resolveInputs "propagatedBuildInputs" attrs.propagatedBuildInputs or [ ];

  doCheck = false;

  dontUseSetuptoolsCheck = true;

  configurePhase = attrs.configurePhase or ''
    rm -f setup.cfg
    rm -f .pylintrc
    ln -s $setupCfg setup.cfg
    ln -s $pylintrc .pylintrc
  '';

  targetSetup = if (args ? targetSetup && lib.isDerivation args.targetSetup) then args.targetSetup else
  (base.mkTargetSetup {
    name = args.targetSetup.name or args.name;
    markerFiles = args.targetSetup.markerFiles or [ ] ++ [ "setup.py" "setup.cfg" "pyproject.toml" ];
    templateDir = pkgs.symlinkJoin {
      name = "python-component-template";
      paths = (
        lib.optional (args ? targetSetup.templateDir) args.targetSetup.templateDir
      ) ++ [ ./component-template ];
    };
    variables = (rec {
      inherit version;
      pname = name;
      mainPackage = lib.toLower (builtins.replaceStrings [ "-" " " ] [ "_" "_" ] name);
      entryPoint = if setuptoolsLibrary then "{}" else "{\\\"console_scripts\\\": [\\\"${name}=${mainPackage}.main:main\\\"]}";
    } // args.targetSetup.variables or { });
    variableQueries = ({
      desc = "✍️ Write a short description for your component:";
      author = "🤓 Enter author name:";
      email = "📧 Enter author email:";
      url = "🏄 Enter author website url:";
    } // args.targetSetup.variableQueries or { });
    initCommands = "black .";
  });

  shellCommands = base.mkShellCommands name ({
    check = {
      script = ''eval $installCheckPhase'';
      description = "Run lints and tests.";
    };
    format = {
      script = "black . && isort .";
      description = "Format the code.";
    };
    build = {
      script = ''eval $buildPhase'';
      show = false;
    };
  } // attrs.shellCommands or { });

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
    ${attrs.shellHook or ""}
  '';
}))
