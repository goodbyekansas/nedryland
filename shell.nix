{ pkgs, components, mapComponentsRecursive, parseConfig, enableChecksOnComponent, extraShells ? { } }:
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
        builtins.map (c: getAllPackages c) (builtins.filter (c: builtins.isAttrs c) (builtins.attrValues components))
    );

  all = pkgs.mkShell {
    buildInputs = (getAllPackages components);
  };
in
(mapComponentsRecursive
  (
    attrName: component':
      (
        let
          # we want the check version of the component for
          # the shell (but not for dependencies of it)
          # that is the reason we are not using the check
          # variant of the matrix
          component = enableChecksOnComponent component';
          derivationShells =
            builtins.mapAttrs
              (name: drv:
                let
                  targetName = "${component.name}.${name}";
                  shellPkg = (drv.drvAttrs // {
                    name = "${targetName}-shell";

                    # this will get merged with nativeBuildInputs
                    # from "drv" inside mkShell so no need to
                    # add to it here
                    nativeBuildInputs = (drv.shellInputs or [ ]);

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
                      echo 🐚 Running shell hook for \"${targetName}\"
                      ${drv.shellHook or ""}
                      echo 🥂 You are now in a shell for working on \"${targetName}\"
                    '';
                  });
                in
                pkgs.mkShell.override
                  {
                    stdenv = drv.stdenv;
                  }
                  shellPkg
              )
              (pkgs.lib.filterAttrs (n: v: pkgs.lib.isDerivation v) component);

          defaultShell =
            if (builtins.length (builtins.attrValues derivationShells)) == 1 then
              builtins.head (builtins.attrValues derivationShells)
            else
              derivationShells."${config.defaultTarget}";
        in
        defaultShell.overrideAttrs (oldAttrs: {
          passthru = derivationShells;
        })
      )
  )
  components) // extraShells // {
  inherit all;
}
