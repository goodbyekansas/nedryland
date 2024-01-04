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
          mkShellForComponent = component: attributePath:
            builtins.mapAttrs
              (name: drv:
                drv.overrideAttrs (oldAttrs:
                  let
                    targetName = lib.escapeShellArg ''target "\x1b[1m${name}\x1b[0m" in "\x1b[1m${builtins.concatStringsSep "." attributePath}\x1b[0m"'';
                    shellCommandAttrsOrDrv = oldAttrs.passthru.shellCommands or
                      oldAttrs.shellCommands or { };
                    shellCommands =
                      if lib.isDerivation shellCommandAttrsOrDrv then
                        shellCommandAttrsOrDrv
                      else
                        mkShellCommands (oldAttrs.name or oldAttrs.pname or "no-name") shellCommandAttrsOrDrv;
                  in
                  {
                    inherit shellCommands;
                    name = "${component.name}-${oldAttrs.name or oldAttrs.pname or "no-name"}-shell";

                    # add shell inputs and commands to native build inputs
                    #
                    # Priority of nativeBuildInputs then becomes:
                    #  1. nativeBuildInputs
                    #  2. shellInputs
                    #  3. shellCommands
                    #  4. nativeCheckInputs/checkInputs/installCheckInputs
                    nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
                    ++ oldAttrs.passthru.shellInputs or [ ]
                    ++ oldAttrs.shellInputs or [ ]
                    ++ [ shellCommands ];

                    # set componentDir here to be able to access
                    # it inside the shell as $componentDir if we wish
                    componentDir =
                      let
                        possibleSources = lib.optionals
                          (oldAttrs ? src)
                          [ (oldAttrs.src.origSrc or null) oldAttrs.src ];
                      in
                      builtins.toString (lib.findFirst
                        (p: p != null && !lib.isStorePath p)
                        component.path
                        possibleSources);

                    shellHook = ''
                      componentDir="$componentDir"
                      if [ -f "$componentDir" ]; then
                        componentDir=$(dirname "$componentDir")
                      fi

                      # This is for `nix develop` and flakes.
                      if [[ "$componentDir" =~ ^/nix/store/.*$ ]]; then
                        git_root=$(${git}/bin/git rev-parse --show-toplevel)
                        target_relative="$(echo "$componentDir" | cut -d/ -f 5-)"
                        componentDir="$git_root/$target_relative"
                      fi
                      echo ⛑ Changing dir to \"$componentDir\"
                      cd "$componentDir"
                      echo -e 🐚 Running shell hook for ${targetName}
                      ${oldAttrs.shellHook or ""}
                      echo -e 🥂 You are now in a shell for working on ${targetName}
                      echo "Available commands for this shell are:"
                      shellHelp
                    '';

                    preferLocalBuild = true;
                  })
              )
              (lib.filterAttrs (_n: t: lib.isDerivation t && !(t.isNedrylandComponent or false)) component.componentAttrs);

          componentShells = mkShellForComponent component pth;
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
            {
              docs = mkShell {
                shellHook = ''
                  echo -e '\x1b[31mInvalid shell "docs"!\x1b[0m'
                  echo '🐚 The docs attribute is just the combination of the sub-targets.'
                  echo '🎯 Available sub-targets are: ${builtins.concatStringsSep ", " (builtins.attrNames (lib.filterAttrs (_: lib.isDerivation) component.docs.passthru))}'
                  exit 1
                '';
                passthru = mkShellForComponent
                  {
                    inherit (component) name path;
                    componentAttrs = component.docs;
                  }
                  (pth ++ [ "docs" ]);
              };
            };
        })
      )
  )
  components) // extraShells // {
  all = mkShell {
    nativeBuildInputs = getAllTargets components;
  };
}
