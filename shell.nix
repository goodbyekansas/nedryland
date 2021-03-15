{ pkgs, components, mapComponentsRecursive, parseConfig, extraShells ? { } }:
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
    attrName: component:
      (
        let
          derivationShells =
            builtins.mapAttrs
              (name: drv:
                let
                  targetName = "${component.name}.${name}";
                  shellPkg = drv.drvAttrs // rec {
                    name = "${targetName}-shell";
                    nativeBuildInputs = drv.shellInputs or [ ]
                    ++ drv.checkInputs or [ ]
                    ++ drv.installCheckInputs or [ ];

                    # we will get double shellhooks if we do not
                    # remove this here
                    inputsFrom = [ (builtins.removeAttrs drv [ "shellHook" ]) ];

                    componentDir = builtins.toString component.path;
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
                  };
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
