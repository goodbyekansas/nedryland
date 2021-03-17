let
  sources = import ./nix/sources.nix;

  pkgs = with
    {
      overlay = _: pkgs:
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
          (import ./overlays/python_packages.nix)

          # comment here
          (import ./overlays/wasmer.nix)

          # more recent Wasi lib C (default was 2019)
          (import ./overlays/wasilibc.nix)

          # darwin "fix" for mingw
          (import ./overlays/darwin-fix-mcfgthreads.nix)
        ];
        config = { };
      };
in
{

  docs = pkgs.stdenv.mkDerivation rec {
    name = "nedryland-docs";
    src = builtins.path { inherit name; path = ./docs; };
    buildInputs = [ pkgs.mdbook ];
    buildPhase = "mdbook build --dest-dir book";
    installPhase = ''
      mkdir -p $out
      cp -r book/. $out
    '';
  };

  ci = pkgs.runCommand "ci-scripts"
    {
      nixpkgsFmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
      diff = "${pkgs.diffutils}/bin/diff";
      mktemp = "${pkgs.mktemp}/bin/mktemp";
      # Pointless to do this on a remote machine.
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      n=$out/bin/nixfmt
      mkdir -p "$(dirname "$n")"
      substituteAll ${./ci/nix-fmt.bash} $n
      chmod +x "$n"
    '';

  mkProject =
    attrs@{ name
    , components
    , baseExtensions ? [ ]
    , extraShells ? { }
    , configFile ? null
    , lib ? { }
    , dependencies ? [ ]
    , ...
    }:
    pkgs.lib.makeOverridable
      ({ enableChecks }:
      let
        componentFns = import ./component.nix pkgs;

        # create the non-extended base
        createMinimalBase = { mkComponent }:
          let
            mkComponent' = mkComponent minimalBase.deployment.mkCombinedDeployment;
            minimalBase = {
              inherit
                sources
                callFile
                callFunction;
              mapComponentsRecursive = componentFns.mapComponentsRecursive;
              mkComponent = mkComponent';
              mkClient = targets@{ name, ... }: mkComponent' targets;
              mkService = targets@{ name, ... }: mkComponent' targets;
              extend = import ./extend.nix pkgs.lib.toUpper;
              theme = import ./theme/default.nix pkgs;
              parseConfig = import ./config.nix pkgs configContent (pkgs.lib.toUpper name);
              deployment = import ./deployment.nix pkgs minimalBase;
              languages = import ./languages pkgs minimalBase;
            };
          in
          minimalBase;

        evalBaseExtensionsWith = baseExtensions: initialBase: components:
          (builtins.foldl'
            (
              combinedBaseExtensions: currentBaseExtension:
                let
                  extFn = import currentBaseExtension;
                  args = builtins.functionArgs extFn;
                in
                pkgs.lib.recursiveUpdate combinedBaseExtensions (
                  extFn (
                    builtins.intersectAttrs args components //
                    builtins.intersectAttrs args pkgs // {
                      base = (pkgs.lib.recursiveUpdate combinedBaseExtensions initialBase);
                    }
                  )
                )
            )
            { }
            baseExtensions
          );

        # extend base with base extensions from this and dependent projects
        extendBase = minimalBase:
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


        # create the final, extended base and make it overridable
        minimalBase = pkgs.lib.makeOverridable createMinimalBase {
          mkComponent = componentFns.mkComponent enableChecks ./.;
        };
        base = extendBase minimalBase;

        # callFile and callFunction will auto-populate dependencies
        # on nixpkgs, base members and project components
        callFile = path: overrides: callFunction (import path) path overrides;
        callFunction = function: path: overrides: pkgs.lib.makeOverridable
          (
            overrides:
            let
              args = builtins.functionArgs function;
              newBase = extendBase (minimalBase.override {
                # burn the path into mkComponent
                mkComponent = componentFns.mkComponent enableChecks path;
              });
            in
            function
              (
                (builtins.intersectAttrs args pkgs)
                // (builtins.intersectAttrs args resolvedComponents)
                // (builtins.intersectAttrs args { base = newBase; })
                // overrides
              )
          )
          overrides;

        # we support most arguments to mkProject being functions
        # that accept a minimal base
        appliedAttrs =
          builtins.mapAttrs
            (n: v:
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

        resolvedComponents = appliedAttrs.components;
        resolvedNedrylandComponents = (pkgs.lib.collect (value: value.isNedrylandComponent or false) resolvedComponents);

        # create a set of all available targets on all components
        # for use as one axis in the matrix
        allTargets = ((pkgs.lib.zipAttrs (
          builtins.map
            (
              comp: pkgs.lib.filterAttrs
                (
                  name: value: name != "allTargets" && pkgs.lib.isDerivation value
                )
                comp
            )
            resolvedNedrylandComponents
        )) // {
          all = builtins.foldl'
            (acc: cur:
              acc ++ cur.allTargets
            )
            [ ]
            resolvedNedrylandComponents;
        });

        # any extra attributes are assumed to be targets in the matrix
        extraTargets = builtins.mapAttrs
          (
            name: value: if builtins.isFunction value then value resolvedComponents else value
          )
          (builtins.removeAttrs appliedAttrs [
            "components"
            "extraShells"
            "lib"
            "baseExtensions"
            "configFile"
            "name"
            "dependencies"
          ]);
      in
      rec {
        name = appliedAttrs.name;

        lib = appliedAttrs.lib or { };
        baseExtensions = appliedAttrs.baseExtensions or [ ];
        dependencies = appliedAttrs.dependencies or [ ];

        nixpkgs = pkgs;
        nixpkgsPath = sources.nixpkgs;

        components = resolvedComponents;
        targets = allTargets // extraTargets;
        matrix = components // targets;

        shells = pkgs.callPackage ./shell.nix {
          inherit components;
          mapComponentsRecursive = minimalBase.mapComponentsRecursive;
          enableChecksOnComponent = componentFns.enableChecksOnComponent;
          parseConfig = minimalBase.parseConfig;
          extraShells = appliedAttrs.extraShells or { };
        };
      })
      {
        # checks are off by default, to turn on, call override on
        # the return value from mkProject and set enableChecks = true
        enableChecks = false;
      };
}
