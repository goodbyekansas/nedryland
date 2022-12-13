{ mkShell
, lib
, git
, components
, mapComponentsRecursive
, parseConfig
, enableChecks
, extraShells ? { }
, mkShellCommands
}:
let
  config = parseConfig {
    key = "shells";
    structure = { defaultTarget = "package"; };
  };

  getAllPackages = components:
    [ ]
    ++ (
      if components.isNedrylandComponent or false then
        [ components._defaultShell or components._default or components."${config.defaultTarget}" ]
      else
        builtins.map getAllPackages (builtins.filter builtins.isAttrs (builtins.attrValues components))
    );

  all = mkShell {
    buildInputs = (getAllPackages components);
  };
in
(mapComponentsRecursive
  (
    _: component:
      (
        let
          toShells = component:
            builtins.mapAttrs
              (_: drv':
                let
                  # we want the check version of the derivation for
                  # the shell (but not for dependencies of it)
                  # that is the reason we are not using the check
                  # variant of the matrix
                  drv =
                    # Priority of nativeBuildInputs is: 
                    #  1. nativeBuildInputs
                    #  2. checkInputs
                    #  3. shellInputs
                    #  4. shellCommands
                    (enableChecks drv').overrideAttrs (oldAttrs: rec{
                      shellCommands = oldAttrs.shellCommands or (mkShellCommands oldAttrs.name { });
                      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
                      ++ oldAttrs.passthru.shellInputs or [ ]
                      ++ oldAttrs.shellInputs or [ ]
                      ++ [ shellCommands ];
                    });
                  targetName = lib.escapeShellArg ''target "${drv.name}" in component "${component.name}"'';
                  shellPkg = (drv.drvAttrs // {
                    inherit (drv) passthru;
                    name = "${component.name}-${drv.name}-shell";

                    # set componentDir here to be able to access
                    # it inside the shell as $componentDir if we wish
                    componentDir =
                      let
                        possibleSources = lib.optionals (drv ? src) [ (drv.src.origSrc or null) drv.src ];
                      in
                      builtins.toString (lib.findFirst (p: p != null && !lib.isStorePath p) component.path possibleSources);

                    # the standard shell hook will:
                    # 1. change directory to the component dir
                    # 2. run the shell hook defined in the target/derivation
                    # 3. celebrate!
                    shellHook = ''
                      componentDir="$componentDir"
                      if [ -f "$componentDir" ]; then
                        componentDir=$(dirname "$componentDir")
                      fi

                      if [[ "$componentDir" == /nix/store/* ]]; then
                        git_root=$(${git}/bin/git rev-parse --show-toplevel)
                        target_relative="$(echo "$componentDir" | cut -d/ -f 5-)"
                        componentDir="$git_root/$target_relative"
                      fi
                      echo ⛑ Changing dir to \"$componentDir\"
                      cd "$componentDir"
                      ${if drv ? targetSetup then "${drv.targetSetup}/bin/target-setup" else ""}
                      echo 🐚 Running shell hook for ${targetName}
                      ${drv.shellHook or ""}
                      echo 🥂 You are now in a shell for working on ${targetName}
                      echo "Available commands for this shell are:"
                      ${drv.shellCommands.helpText}
                    '';
                  });
                in
                mkShell.override
                  {
                    stdenv = drv.stdenv;
                  }
                  shellPkg
              )
              (lib.filterAttrs (_: lib.isDerivation) component);

          derivationShells = toShells component;
          # also include non-derivation attrsets in the passthru property of the top-level
          # shell to support nested components
          derivationsAndAttrsets = (
            lib.filterAttrs
              (
                _: v: builtins.isAttrs v && !lib.isDerivation v
              )
              component
          ) // derivationShells;

          defaultShell =
            if (builtins.length (builtins.attrValues derivationShells)) == 1 then
              builtins.head (builtins.attrValues derivationShells)
            else
              derivationShells._defaultShell or derivationShells._default or derivationShells."${config.defaultTarget}" or (mkShell {
                shellHook = builtins.abort ''
                  🐚 Could not decide on a default shell for component "${component.name}"
                  🎯 Available targets are: ${builtins.concatStringsSep ", " (builtins.attrNames derivationShells)}'';
              });
        in
        defaultShell.overrideAttrs (_: {
          passthru = derivationsAndAttrsets // lib.optionalAttrs
            (component ? docs)
            ({
              docs = mkShell {
                shellHook = builtins.abort ''
                  Invalid shell docs!
                  🐚 The docs attribute is just the combination of the sub-targets.
                  🎯 Available sub-targets are: ${builtins.concatStringsSep ", " (builtins.attrNames (lib.filterAttrs (_: lib.isDerivation) component.docs.passthru))}'';
                passthru = toShells (component.docs // { inherit (component) name path; });
              };
            });
        })
      )
  )
  components) // extraShells // {
  inherit all;
}
