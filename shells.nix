{ mkShell
, lib
, components
, mapComponentsRecursive
, parseConfig
, enableChecks
, extraShells ? { }
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
        [ components."${config.defaultTarget}" ]
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
          derivationShells =
            builtins.mapAttrs
              (name: drv':
                let
                  # we want the check version of the derivation for
                  # the shell (but not for dependencies of it)
                  # that is the reason we are not using the check
                  # variant of the matrix
                  drv = enableChecks drv';
                  targetName = "${component.name}.${name}";
                  shellCommandsDesc = lib.filterAttrs (_: value: value.show) (drv.shellCommands or { })._descriptions or { };
                  shellPkg = (drv.drvAttrs // {
                    inherit (drv) passthru;
                    name = "${targetName}-shell";

                    # this will get merged with nativeBuildInputs
                    # from "drv" inside mkShell so no need to
                    # add to it here
                    nativeBuildInputs = drv.shellInputs or [ ] ++ (lib.optional (drv ? shellCommands) drv.shellCommands);

                    # we will get double shellhooks if we do not
                    # remove this here
                    inputsFrom = [ (builtins.removeAttrs drv [ "shellHook" ]) ];

                    # set componentDir here to be able to access
                    # it inside the shell as $componentDir if we wish
                    componentDir = builtins.toString component.path;

                    # the standard shell hook will:
                    # 1. change directory to the component dir
                    # 2. run the shell hook defined in the target/derivation
                    # 3. celebrate!
                    shellHook = ''
                      componentDir="$componentDir"
                      if [ -f "$componentDir" ]; then
                        componentDir=$(dirname "$componentDir")
                      fi

                      echo ⛑ Changing dir to \"$componentDir\"
                      cd "$componentDir"
                      ${if drv ? targetSetup then "${drv.targetSetup}/bin/target-setup" else ""}
                      echo 🐚 Running shell hook for \"${targetName}\"
                      ${drv.shellHook or ""}
                      echo 🥂 You are now in a shell for working on \"${targetName}\"
                      esc=$(printf '\e[')
                      ${if shellCommandsDesc != { } then ''echo "Available commands for this shell are:"'' else ""}
                      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (name: desc:
                        ''echo "  ''${esc}32m${name}''${esc}0m ''${esc}33m${desc.args}''${esc}0m" ${if desc.description != "" then '';echo "    ${builtins.replaceStrings ["\n"] ["\n    "] desc.description}"'' else ""}'')
                        shellCommandsDesc)}
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
              derivationShells."${config.defaultTarget}" or (mkShell {
                shellHook = builtins.abort ''
                  🐚 Could not decide on a default shell for component "${component.name}"
                  🎯 Available targets are: ${builtins.concatStringsSep ", " (builtins.attrNames derivationShells)}'';
              });
        in
        defaultShell.overrideAttrs (_: {
          passthru = derivationsAndAttrsets;
        })
      )
  )
  components) // extraShells // {
  inherit all;
}
