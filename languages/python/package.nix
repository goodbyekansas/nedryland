{ base, pkgs, defaultPythonVersion }:
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
  resolveInputs = (import ./utils.nix).resolveInputs pythonPkgs;

  customerFilter = src:
    let
      # IMPORTANT: use a let binding like this to memoize info about the git directories.
      srcIgnored = pkgs.gitignoreFilter src;
    in
    path: type:
      (srcIgnored path type) && !(builtins.any (pred: pred path type) srcExclude);
  filteredSrc =
    if srcExclude != [ ] && args ? src then
      pkgs.lib.cleanSourceWith
        {
          inherit (args) src;
          filter = customerFilter args.src;
          name = "${name}-source";
        } else pkgs.gitignoreSource args.src;
  src = if pkgs.lib.isStorePath args.src then args.src else filteredSrc;

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

  attrs = builtins.removeAttrs args [ "srcExclude" "shellInputs" "targetSetup" "docs" ];
in
pythonPkgs.buildPythonPackage (attrs // {
  inherit src version setupCfg pylintrc format preBuild doStandardTests;
  pname = name;

  # Dependencies needed for running the checkPhase. These are added to nativeBuildInputs when doCheck = true. Items listed in tests_require go here.
  checkInputs = with pythonPkgs; [
    python-language-server
    pyls-mypy
    pyls-isort
  ] ++ (resolveInputs attrs.checkInputs or (_: [ ]));

  # Build and/or run-time dependencies that need to be be compiled
  # for the host machine. Typically non-Python libraries which are being linked.
  buildInputs = resolveInputs attrs.buildInputs or (_: [ ]);

  # Build-time only dependencies. Typically executables as well
  # as the items listed in setup_requires
  nativeBuildInputs = resolveInputs attrs.nativeBuildInputs or (_: [ ]);

  passthru = { shellInputs = (resolveInputs args.shellInputs or (_: [ ])); };

  # Aside from propagating dependencies, buildPythonPackage also injects
  # code into and wraps executables with the paths included in this list.
  # Items listed in install_requires go here
  propagatedBuildInputs = resolveInputs attrs.propagatedBuildInputs or (_: [ ]);

  doCheck = false;

  dontUseSetuptoolsCheck = true;

  configurePhase = attrs.configurePhase or ''
    rm -f setup.cfg
    rm -f .pylintrc
    ln -s $setupCfg setup.cfg
    ln -s $pylintrc .pylintrc
  '';

  targetSetup = base.mkTargetSetup {
    name = args.targetSetup.name or "python";
    markerFiles = args.targetSetup.markerFiles or [ ] ++ [ "setup.py" ];
    templateDir = pkgs.symlinkJoin {
      name = "python-component-template";
      paths = (
        pkgs.lib.optional (args ? targetSetup.templateDir) args.targetSetup.templateDir
      ) ++ [ ./component-template ];
    };
    variables = (rec {
      inherit version;
      pname = name;
      mainPackage = pkgs.lib.toLower (builtins.replaceStrings [ "-" " " ] [ "_" "_" ] name);
      entryPoint = if setuptoolsLibrary then "{}" else "{\\\"console_scripts\\\": [\\\"${name}=${mainPackage}.main:main\\\"]}";
    } // args.targetSetup.variables or { });
    variableQueries = ({
      desc = "✍️ Write a short description for your component:";
      author = "🤓 Enter author name:";
      email = "📧 Enter author email:";
      url = "🏄 Enter author website url:";
    } // args.targetSetup.variableQueries or { });
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

    check() {
        eval "$installCheckPhase"
    }
    ${attrs.shellHook or ""}
  '';

  postFixup = ''
    ${attrs.postFixup or ""}
    mkdir -p $out/nedryland
    touch $out/nedryland/add-to-mypy-path
  '';
})
