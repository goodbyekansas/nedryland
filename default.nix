{ unFreePkgs ? [ ] }:
let
  sources = import ./nix/sources.nix;

  versions = import ./versions.nix;

  pkgs = with
    {
      overlay = _: _pkgs:
        {
          niv = import sources.niv { };
        };
    };
    import sources.nixpkgs
      {
        overlays = [
          overlay

          # rust
          (import sources.rust)

          # extra pip packages
          (import ./overlays/python-packages.nix)

          # more recent Wasi lib C (default was 2019)
          (import ./overlays/wasm.nix versions)

          # darwin "fix" for mingw
          (import ./overlays/darwin-fix-mcfgthreads.nix)

          # extra pkgs from future versions of nixpkgs
          (import ./overlays/backported-packages.nix)

          # pocl, a CPU-only OpenCL implementation
          (import ./overlays/pocl.nix)

          # gitignore source
          (self: _: { inherit (import sources."gitignore.nix" { lib = self.lib; }) gitignoreSource gitignoreFilter; })
        ];
        config = { allowUnfreePredicate = (pkg: builtins.elem (builtins.parseDrvName pkg.name).name unFreePkgs); };
      };
in
{
  inherit pkgs;
  version = "7.0.0";

  docs = pkgs.stdenv.mkDerivation rec {
    name = "nedryland-docs";
    src = builtins.path { inherit name; path = ./docs; };
    changelog = ./CHANGELOG.md;
    postUnpack = "cp $changelog CHANGELOG.md";
    buildInputs = [ pkgs.mdbook ];
    buildPhase = "mdbook build --dest-dir book";
    installPhase = ''
      mkdir -p $out/share/doc/nedryland/manual
      cp -r book/. $out/share/doc/nedryland/manual
    '';
  };

  ci = pkgs.runCommand "ci-scripts"
    {
      nixpkgsFmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
      diff = "${pkgs.diffutils}/bin/diff";
      mktemp = "${pkgs.mktemp}/bin/mktemp";
      shellcheck = "${pkgs.shellcheck}/bin/shellcheck";
      shfmt = "${pkgs.shfmt}/bin/shfmt";
      nixLinter = "${pkgs.nix-linter}/bin/nix-linter";
      # Pointless to do this on a remote machine.
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      n=$out/bin/nixfmt
      mkdir -p "$(dirname "$n")"
      substituteAll ${./ci/nix-fmt.bash} $n
      chmod +x "$n"
      n=$out/bin/shellcheck
      mkdir -p "$(dirname "$n")"
      substituteAll ${./ci/shellcheck.bash} $n
      chmod +x "$n"
      n=$out/bin/nix-lint
      mkdir -p "$(dirname "$n")"
      substituteAll ${./ci/nix-lint.sh} $n
      chmod +x "$n"
    '';

  mkTheme = import ./mktheme.nix pkgs;

  mkProject =
    attrs@{ name
    , ...
    }:
    pkgs.lib.makeOverridable
      ({ enableChecks }:
      let
        componentFns = import ./component.nix pkgs;

        # create the non-extended base
        minimalBase =
          let
            parseConfig = import ./config.nix pkgs configContent configRoot (pkgs.lib.toUpper name);
            enableChecksOverride = enable: drv:
              if enable && !(drv.doCheck or false) then
                drv.overrideAttrs
                  (oldAttrs: {
                    doCheck = true;

                    # Python packages don't have a checkPhase, only an installCheckPhase
                    doInstallCheck = true;
                  } // pkgs.lib.optionalAttrs (drv.stdenv.hostPlatform != drv.stdenv.buildPlatform && oldAttrs.doCrossCheck or false) {
                    preInstallPhases = [ "crossCheckPhase" ];
                    crossCheckPhase = oldAttrs.checkPhase or "";
                    nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ] ++ oldAttrs.checkInputs or [ ];
                  }) else drv;

            minimalBase = {
              inherit
                sources
                callFile
                callFunction
                parseConfig
                versions
                enableChecksOverride;
              mkShellCommands = pkgs.callPackage ./shell-commands.nix { };

              # enableChecks is the directive to enable checks.
              # checksEnabled is the state if enabled or not.
              checksEnabled = enableChecks;
              # Overwrite the directive with a function to enable checks.
              enableChecks = enableChecksOverride enableChecks;

              resolveInputs = name: typeName: targets: builtins.map
                (input:
                  if input ? isNedrylandComponent then
                    input."${(pkgs.lib.findFirst
                          (target: builtins.hasAttr target input)
                          (abort "${name}.${typeName} did not contain any of the targets ${builtins.toString targets}. Please specify manually.")
                          targets)}"
                  else
                    input
                );

              mkDerivation = attrs@{ name, stdenv ? pkgs.stdenv, ... }:
                let
                  customerFilter = src:
                    let
                      # IMPORTANT: use a let binding like this to memoize info about the git directories.
                      srcIgnored = pkgs.gitignoreFilter src;
                    in
                    filter:
                    path: type:
                      (srcIgnored path type) && (filter path type);
                  filteredSrc =
                    if attrs ? srcFilter && attrs ? src then
                      pkgs.lib.cleanSourceWith
                        {
                          inherit (attrs) src;
                          filter = customerFilter attrs.src attrs.srcFilter;
                          name = "${name}-source";
                        } else pkgs.gitignoreSource attrs.src;
                in
                minimalBase.enableChecks (stdenv.mkDerivation ((builtins.removeAttrs attrs [ "stdenv" "srcFilter" ]) //
                  {
                    isNedrylandDerivation = true;
                    passthru = (attrs.passthru or { }) // { isNedrylandDerivation = true; };
                    shellCommands = minimalBase.mkShellCommands name attrs.shellCommands or { };
                  }
                  //
                  (pkgs.lib.optionalAttrs (attrs ? src) {
                    src = if pkgs.lib.isStorePath attrs.src then attrs.src else filteredSrc;
                  })));
              inherit (componentFns) mapComponentsRecursive collectComponentsRecursive;
              mkTargetSetup = import ./targetsetup.nix pkgs parseConfig;
              extend = import ./extend.nix pkgs.lib.toUpper;
              deployment = import ./deployment.nix pkgs minimalBase;
              languages = import ./languages pkgs minimalBase versions;
              documentation = import ./documentation pkgs minimalBase;
              setComponentPath = path:
                let
                  overriddenMkComponent = componentFns.mkComponent path minimalBase.deployment.mkCombinedDeployment parseConfig;
                in
                minimalBase // {
                  mkComponent = overriddenMkComponent;
                  mkClient = targets: overriddenMkComponent (targets // { nedrylandType = "client"; });
                  mkService = targets: overriddenMkComponent (targets // { nedrylandType = "service"; });
                  mkLibrary = targets: overriddenMkComponent (targets // { nedrylandType = "library"; });
                };
            };
          in
          minimalBase.setComponentPath ./.;

        evalBaseExtensionsWith = baseExtensions: initialBase: components:
          (builtins.foldl'
            (
              combinedBaseExtensions: currentBaseExtension:
                let
                  extFn = import currentBaseExtension;
                  args = builtins.functionArgs extFn;
                in
                pkgs.lib.recursiveUpdate combinedBaseExtensions (if builtins.isAttrs currentBaseExtension then currentBaseExtension else
                (
                  extFn (
                    builtins.intersectAttrs args (components // { inherit components; }) //
                    builtins.intersectAttrs args pkgs // {
                      base = (pkgs.lib.recursiveUpdate combinedBaseExtensions initialBase);
                    }
                  )
                ))
            )
            { }
            baseExtensions
          );

        # extend base with base extensions from this and dependent projects
        extendBase = minimalBase:
          let
            originalSetComponentPath = minimalBase.setComponentPath;
            inner = minimalBase:
              let
                evalDependenciesBaseExtensions = dependencies: initialBase:
                  builtins.foldl' pkgs.lib.recursiveUpdate initialBase (builtins.map
                    (pd:
                      evalBaseExtensionsWith
                        pd.baseExtensions
                        (evalDependenciesBaseExtensions pd.dependencies initialBase)
                        pd.components
                    )
                    dependencies);

                # evaluate all base extensions from dependent projects recursively
                dependenciesBase = evalDependenciesBaseExtensions (appliedAttrs.dependencies or [ ]) minimalBase;
              in
              # evaluate base extensions for current project
              pkgs.lib.recursiveUpdate dependenciesBase (evalBaseExtensionsWith
                (appliedAttrs.baseExtensions or [ ])
                dependenciesBase
                resolvedComponents);
          in
          (inner minimalBase) // {
            setComponentPath = path: inner (originalSetComponentPath path);
          };


        extendedBase = extendBase minimalBase;

        # callFile and callFunction will auto-populate dependencies
        # on nixpkgs, base members and project components
        callFile = path: callFunction (import path) path;
        callFunction = function: path:
          let
            args = builtins.functionArgs function;
            # Burn the path into newBase
            newBase = extendedBase.setComponentPath path;
          in
          pkgs.lib.makeOverridable
            (
              overrides:
              function
                (
                  (builtins.intersectAttrs args pkgs)
                  // (builtins.intersectAttrs args (resolvedComponents // { components = resolvedComponents; }))
                  // (builtins.intersectAttrs args { base = newBase; })
                  // overrides
                )
            );

        # we support most arguments to mkProject being functions
        # that accept a minimal base
        appliedAttrs =
          builtins.mapAttrs
            (_: v:
              # intersect with minimal base (without extensions) to avoid cyclic deps
              if builtins.isFunction v then
                v (builtins.intersectAttrs (builtins.functionArgs v) minimalBase)
              else
                v
            )
            attrs;

        configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper appliedAttrs.name}_config";
        configContent =
          if configContentFromEnv != "" then configContentFromEnv else
          (
            if appliedAttrs ? configFile
              && builtins.pathExists appliedAttrs.configFile then
              builtins.readFile appliedAttrs.configFile
            else ""
          );
        configRoot = if appliedAttrs ? configFile then builtins.dirOf appliedAttrs.configFile else null;

        resolvedComponents = appliedAttrs.components;
        resolvedNedrylandComponents = componentFns.collectComponentsRecursive resolvedComponents;

        # create a set of all available targets on all components
        # for use as one axis in the matrix
        allTargets = ((pkgs.lib.zipAttrs (
          builtins.map
            (
              pkgs.lib.filterAttrs
                (
                  name: value:
                    name != "allTargets" && (pkgs.lib.isDerivation value || builtins.isList value)
                )
            )
            resolvedNedrylandComponents
        )) // {
          all = builtins.map
            (c: builtins.attrValues (pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) c))
            resolvedNedrylandComponents;
        });

        # any extra attributes are assumed to be targets in the matrix
        extraTargets = builtins.mapAttrs
          (
            _: value: if builtins.isFunction value then value resolvedComponents else value
          )
          (builtins.removeAttrs appliedAttrs [
            "components"
            "extraShells"
            "lib"
            "baseExtensions"
            "configFile"
            "name"
            "dependencies"
            "themes"
          ]);
      in
      (rec {
        inherit (appliedAttrs) name;
        base = extendedBase;
        lib = appliedAttrs.lib or { };
        baseExtensions = appliedAttrs.baseExtensions or [ ];
        dependencies = appliedAttrs.dependencies or [ ];

        nixpkgs = pkgs;
        nixpkgsPath = sources.nixpkgs;

        components = resolvedComponents;
        targets = allTargets // extraTargets;
        matrix = components // targets;

        shells = pkgs.callPackage ./shells.nix {
          inherit components;
          inherit (minimalBase) mkShellCommands mapComponentsRecursive parseConfig;
          enableChecks = minimalBase.enableChecksOverride true;
          extraShells = appliedAttrs.extraShells or { };
        };
      } // (pkgs.lib.optionalAttrs (appliedAttrs ? version) { inherit (appliedAttrs) version; })))
      {
        # checks are off by default, to turn on, call override on
        # the return value from mkProject and set enableChecks = true
        enableChecks = false;
      };
}
