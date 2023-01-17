{ mkShell
, lib
, git
, components
, collectComponentsRecursive
, mapComponentsRecursive
, parseConfig
, extraShells ? { }
, mkShellCommands
}:
let
  config = parseConfig {
    key = "shells";
    structure = { defaultTarget = "package"; };
  };

  getAllTargets = components:
    builtins.map
      (component:
        component.componentAttrs._defaultShell
          or component.componentAttrs._default
          or component.componentAttrs."${config.defaultTarget}"
          or null
      )
      (collectComponentsRecursive components);
in
(mapComponentsRecursive
  (
    pth: component:
      (
        let
          mkShellForComponent = component:
            builtins.mapAttrs
              (name: drv:
                let
                  # add shell inputs and commands to native build inputs
                  # note that this has to run after the shell derivation is created to let
                  # it first run its logic on nativeBuildInputs ++
                  # checkInputs/installCheckInputs
                  #
                  # Priority of nativeBuildInputs then becomes:
                  #  1. nativeBuildInputs
                  #  2. checkInputs/installCheckInputs
                  #  3. shellInputs
                  #  4. shellCommands
                  addShellInputs = drv: drv.overrideAttrs (oldAttrs:
                    let
                      shellCommandAttrsOrDrv = oldAttrs.passthru.shellCommands or
                        oldAttrs.shellCommands or { };
                      shellCommands =
                        if lib.isDerivation shellCommandAttrsOrDrv then
                          shellCommandAttrsOrDrv
                        else
                          mkShellCommands oldAttrs.name shellCommandAttrsOrDrv;
                    in
                    {
                      inherit shellCommands;
                      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
                      ++ oldAttrs.passthru.shellInputs or [ ]
                      ++ oldAttrs.shellInputs or [ ]
                      ++ [ shellCommands ];
                    });

                  targetName = lib.escapeShellArg ''target "${name}" in component "${builtins.concatStringsSep "." pth}"'';
                  shellPkg = (drv.drvAttrs // {
                    inherit (drv) passthru;
                    name = "${component.name}-${drv.name}-shell";

                    # set componentDir here to be able to access
                    # it inside the shell as $componentDir if we wish
                    componentDir =
                      let
                        possibleSources = lib.optionals
                          (drv ? src)
                          [ (drv.src.origSrc or null) drv.src ];
                      in
                      builtins.toString (lib.findFirst
                        (p: p != null && !lib.isStorePath p)
                        component.path
                        possibleSources);

                    # the standard shell hook will:
                    # 1. change directory to the component dir
                    # 2. run the shell hook defined in the target/derivation
                    # 3. celebrate!
                    shellHook = ''
                      componentDir="$componentDir"
                      if [ -f "$componentDir" ]; then
                        componentDir=$(dirname "$componentDir")
                      fi

                      # This is for `nix develop` and flakes.
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
                      shellHelp
                    '';
                  });
                in
                addShellInputs
                  (mkShell.override
                    {
                      stdenv = drv.stdenv;
                    }
                    shellPkg)
              )
              (lib.filterAttrs (_n: t: lib.isDerivation t && !(t.isNedrylandComponent or false)) component.componentAttrs);

          componentShells = mkShellForComponent component;
          componentShellsAndSubComponents = componentShells // component.nedrylandComponents;

          defaultShell =
            # ._defaultShell -> ._default -> config defaultTarget -> only one derivation?
            # -> error
            componentShells._defaultShell or
              componentShells._default or
                componentShells."${config.defaultTarget}" or
                  (if (builtins.length (builtins.attrValues componentShells)) == 1 then
                    builtins.head (builtins.attrValues componentShells)
                  else
                    (mkShell {
                      name = "error-shell";
                      shellHook = ''
                        echo '🐚 Could not decide on a default shell for component "${component.name}"'
                        echo '🎯 Available targets/sub-components are: ${builtins.concatStringsSep ", " (builtins.attrNames componentShellsAndSubComponents)}'
                        exit 1
                      '';
                    }));

        in
        defaultShell.overrideAttrs (_: {
          passthru = componentShellsAndSubComponents // lib.optionalAttrs
            (component ? docs)
            ({
              docs = mkShell {
                shellHook = ''
                  Invalid shell "docs"!
                  echo '🐚 The docs attribute is just the combination of the sub-targets.'
                  echo '🎯 Available sub-targets are: ${builtins.concatStringsSep ", " (builtins.attrNames (lib.filterAttrs (_: lib.isDerivation) component.docs.passthru))}'
                  exit 1
                '';
                passthru = mkShellForComponent (component.docs // { inherit (component) name path; });
              };
            });
        })
      )
  )
  components) // extraShells // {
  all = mkShell {
    nativeBuildInputs = getAllTargets components;
  };
}
