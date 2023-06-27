let
  gitignore = import (builtins.fetchTarball {
    url = "https://github.com/hercules-ci/gitignore.nix/archive/a20de23b925fd8264fd7fad6454652e142fd7f73.tar.gz";
    sha256 = "sha256:07vg2i9va38zbld9abs9lzqblz193vc5wvqd6h7amkmwf66ljcgh";
  });

  gitIgnoreOverlay = _: prev: (gitignore {
    lib = prev.lib // (prev.lib.optionalAttrs (! prev.lib ? inPureEvalMode) {
      inPureEvalMode = ! builtins ? currentSystem;
    });
  });

  f = { pkgs, skipNixpkgsVersionCheck ? false }:
    assert pkgs.lib.assertMsg
      (!skipNixpkgsVersionCheck && pkgs.lib.versionAtLeast (builtins.replaceStrings [ "pre-git" ] [ "" ] (pkgs.lib.version or "0.0.0")) "22.05")
      "Nedryland supports nixpkgs versions >= 22.05, you have ${pkgs.lib.version or "unknown"}}";
    let
      pkgs' = pkgs.extend gitIgnoreOverlay;
      version = "8.3.3";
      versionAtLeast = pkgs'.lib.versionAtLeast version;
    in
    {
      inherit version versionAtLeast;
      pkgs = pkgs';

      docs = pkgs'.stdenv.mkDerivation rec {
        name = "nedryland-docs";
        src = builtins.path { inherit name; path = ./docs; };
        changelog = ./CHANGELOG.md;
        postUnpack = "cp $changelog CHANGELOG.md";
        buildInputs = [ pkgs'.mdbook ];
        buildPhase = "mdbook build --dest-dir book";
        installPhase = ''
          mkdir -p $out/share/doc/nedryland/manual
          cp -r book/. $out/share/doc/nedryland/manual
        '';
      };

      checks = pkgs'.callPackage ./ci { };

      mkTheme = import ./mktheme.nix pkgs';

      mkProject =
        attrs@{ name
        , ...
        }:
        let
          configContentFromEnv = builtins.getEnv "${pkgs'.lib.toUpper appliedAttrs.name}_config";
          configContent =
            if configContentFromEnv != "" then configContentFromEnv else
            (
              if appliedAttrs ? configFile
                && builtins.pathExists appliedAttrs.configFile then
                builtins.readFile appliedAttrs.configFile
              else ""
            );
          configRoot = if appliedAttrs ? configFile then builtins.dirOf appliedAttrs.configFile else null;
          parseConfig = import ./config.nix pkgs' configContent configRoot (pkgs'.lib.toUpper name);
          deployment = import ./deployment.nix pkgs';
          componentFns = import ./component.nix pkgs' deployment.mkCombinedDeployment parseConfig;

          # create the non-extended base
          minimalBase =
            let

              minimalBase = {
                inherit
                  version
                  versionAtLeast
                  callFile
                  callFunction
                  parseConfig;
                mkShellCommands = pkgs'.callPackage ./shell-commands.nix { };

                inCI = builtins.stringLength (builtins.getEnv "CI") > 0;

                resolveInputs = name: typeName: targets: builtins.map
                  (input:
                    if input ? isNedrylandComponent then
                      input."${(pkgs'.lib.findFirst
                          (target: builtins.hasAttr target input)
                      (abort "${name}.${typeName} did not contain any of the targets ${builtins.toString targets}. Please specify a valid target.")
                          targets)}"
                    else
                      input
                  );

                mkDerivation = attrs@{ stdenv ? pkgs'.stdenv, ... }:
                  assert pkgs'.lib.assertMsg
                    (!(attrs ? name) -> attrs ? pname && attrs ? version)
                    "mkDerivation missing required argument name, alternatively supply pname and version.";
                  let
                    customerFilter = src:
                      let
                        # IMPORTANT: use a let binding like this to memoize info about the git directories.
                        srcIgnored = pkgs'.gitignoreFilter src;
                      in
                      filter:
                      path: type:
                        (srcIgnored path type) && (filter path type);
                    filteredSrc =
                      if attrs ? srcFilter && attrs ? src then
                        pkgs'.lib.cleanSourceWith
                          {
                            inherit (attrs) src;
                            filter = customerFilter attrs.src attrs.srcFilter;
                            name = "${attrs.name or attrs.pname}-source";
                          } else pkgs'.gitignoreSource attrs.src;
                  in
                  stdenv.mkDerivation ((builtins.removeAttrs attrs [ "stdenv" "srcFilter" "shellCommands" ]) //
                    {
                      isNedrylandDerivation = true;
                      passthru = (attrs.passthru or { }) // {
                        isNedrylandDerivation = true;
                        shellCommands = attrs.shellCommands or { };
                      };
                      shellInputs = attrs.shellInputs or [ ] ++ pkgs'.lib.optional (attrs ? targetSetup) attrs.targetSetup;
                    }
                    // pkgs'.lib.optionalAttrs (attrs.doCheck or true)
                    (
                      let checkAttrs = {
                        # LintPhase for checks that does not require to run the built program
                        lintPhase = attrs.lintPhase or ''echo "No lintPhase defined, doing nothing"'';
                        preInstallPhases = attrs.preInstallPhases or [ ] ++ [ "lintPhase" ];
                        nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ attrs.lintInputs or [ ];
                      };
                      in
                      (checkAttrs // pkgs'.lib.optionalAttrs (stdenv.hostPlatform != stdenv.buildPlatform && attrs.doCrossCheck or false) {
                        crossCheckPhase = attrs.crossCheckPhase or attrs.checkPhase or ''echo "No checkPhase or crossCheckPhase defined (but doCrossCheck is true), doing nothing"'';
                        preInstallPhases = checkAttrs.preInstallPhases ++ [ "crossCheckPhase" ];
                        nativeBuildInputs = checkAttrs.nativeBuildInputs ++ attrs.checkInputs or [ ];
                      })
                    )
                    // (pkgs'.lib.optionalAttrs (attrs ? src) {
                    src = if pkgs'.lib.isStorePath attrs.src then attrs.src else filteredSrc;
                  }));
                inherit (componentFns) mapComponentsRecursive collectComponentsRecursive mkComponentSet;
                inherit deployment;
                mkTargetSetup = import ./target-setup pkgs' parseConfig;
                documentation = import ./documentation pkgs' minimalBase;
                setComponentPath = path:
                  let
                    overriddenMkComponent = componentFns.mkComponent path;
                  in
                  minimalBase // {
                    mkComponentSet = componentFns.mkComponentSet overriddenMkComponent;
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
                    extFn = if builtins.isPath currentBaseExtension then import currentBaseExtension else currentBaseExtension;
                    args = builtins.functionArgs extFn;
                  in
                  pkgs'.lib.recursiveUpdate combinedBaseExtensions (if builtins.isAttrs currentBaseExtension then currentBaseExtension else
                  (
                    extFn (
                      builtins.intersectAttrs args (components // { inherit components; })
                      // builtins.intersectAttrs args pkgs'
                      // builtins.intersectAttrs args (let base = (pkgs'.lib.recursiveUpdate initialBase combinedBaseExtensions); in base // { inherit base; })
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
                    builtins.foldl' pkgs'.lib.recursiveUpdate initialBase (builtins.map
                      (pd:
                        evalBaseExtensionsWith
                          pd.baseExtensions
                          (evalDependenciesBaseExtensions pd.dependencies initialBase)
                          pd.components.nedrylandComponents
                      )
                      dependencies);

                  # evaluate all base extensions from dependent projects recursively
                  dependenciesBase = evalDependenciesBaseExtensions (appliedAttrs.dependencies or [ ]) minimalBase;
                in
                # evaluate base extensions for current project
                pkgs'.lib.recursiveUpdate dependenciesBase (evalBaseExtensionsWith
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
            pkgs'.lib.makeOverridable
              (
                overrides:
                function
                  (
                    (builtins.intersectAttrs args pkgs')
                    // (builtins.intersectAttrs args (resolvedComponents // { components = resolvedComponents; }))
                    // (builtins.intersectAttrs args (newBase // { base = newBase; }))
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

          resolvedComponents = appliedAttrs.components;
          resolvedNedrylandComponents = componentFns.collectComponentsRecursive resolvedComponents;

          # create a set of all available targets
          # for use as one axis in the matrix
          allTargets =
            builtins.mapAttrs
              (target: drvs:
                # create a link farm where each link has the name of the access path to
                # the component. I.e. the target `tgt` in the component `myComponent`
                # has the link name `myComponent` so that if you `nix build
                # .#targets.tgt` followed by `ls -l result/` you will see `myComponent
                # -> /nix/store/something`.
                extendedBase.mkComponentSet
                  target
                  (builtins.listToAttrs (builtins.map
                    (value: {
                      inherit value;
                      name = builtins.concatStringsSep "." (value.accessPath ++ [ target ]);
                    })
                    drvs)))
              (pkgs'.lib.zipAttrs
                (
                  builtins.map
                    (comp:
                      # add the accessPath of the component to the individual
                      # drvs to be able to use in linkfarm above.
                      # looks like `[ "grandParentComponent" "parentComponent" "component" ]`
                      builtins.mapAttrs
                        (_: v: v // { inherit (comp) accessPath; })
                        (pkgs'.lib.filterAttrs
                          (
                            name: value:
                              name != "_default" &&
                              (pkgs'.lib.isDerivation value) &&
                              !(value.isNedrylandComponent or false)
                          )
                          comp.componentAttrs)
                    )
                    resolvedNedrylandComponents
                ));


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
              "version"
            ]);
          componentSet = builtins.mapAttrs
            (name: value:
              if pkgs.lib.isDerivation value then
                value
              else
                if builtins.isAttrs value then
                  extendedBase.mkComponentSet
                    name
                    value
                else
                  builtins.throw "components can only be attrsets or derivations."
            )
            (resolvedComponents // extraTargets);
        in
        (rec {
          inherit (appliedAttrs) name;
          pkgs = pkgs';

          base = extendedBase;
          lib = appliedAttrs.lib or { };
          baseExtensions = appliedAttrs.baseExtensions or [ ];
          dependencies = appliedAttrs.dependencies or [ ];

          # x-axis
          components = extendedBase.mkComponentSet
            "components"
            componentSet;

          # y-axis
          targets = extendedBase.mkComponentSet
            "targets"
            allTargets;

          # matrix
          matrix = componentSet // { inherit targets; };

          # do not fall for the temptation to use callPackage here. callPackage blindly
          # adds "override" and "overrideDerivation" functions which will break flake
          # checks since functions are not derivations.
          shells =
            let
              f = import ./shells.nix;
            in
            f ((builtins.intersectAttrs (builtins.functionArgs f) pkgs') // {
              components = componentSet;
              inherit (minimalBase) mkShellCommands mapComponentsRecursive parseConfig collectComponentsRecursive;
              extraShells = appliedAttrs.extraShells or { };
            });

        } // (pkgs'.lib.optionalAttrs
          (appliedAttrs ? version)
          { inherit (appliedAttrs) version; }));
      override =
        f;
    };
in
f

