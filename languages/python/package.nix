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

  attrs = builtins.removeAttrs args [ "srcExclude" "shellInputs" "targetSetup" "docs" ];
in
base.enableChecks (pythonPkgs.buildPythonPackage (attrs // {
  inherit src version format preBuild doStandardTests pythonVersion;
  pname = name;

  # Build and/or run-time dependencies that need to be be compiled
  # for the host machine. Typically non-Python libraries which are being linked.
  buildInputs = resolveInputs "buildInputs" attrs.buildInputs or [ ];

  passthru = {
    shellInputs = (resolveInputs "shellInputs" args.shellInputs or [ ])
      ++ [ pythonPkgs.python-lsp-server pythonPkgs.pylsp-mypy pythonPkgs.pyls-isort ];
  };

  doCheck = false;

  dontUseSetuptoolsCheck = true;

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
    show-generated-config = {
      script = "$1 --print-generated-config";
      args = "<linter>";
      description = ''
        Show the config Nedryland has generated for a linter, one of:
        black, coverage, flake8, isort, mypy, pylint, pytest'';
    };
  } // attrs.shellCommands or { });

}))
