{ configuredGrid }:
  builtins.mapAttrs (compName: v: (v.component.package.overrideAttrs (oldAttrs: {
    shellHook = ''
      echo 🏗️ Changing dir to \"${builtins.dirOf v.pth}\"
      cd ${builtins.dirOf v.pth}
      echo 🐚 Running shell hook for \"${v.component.package.name}\"
      ${oldAttrs.shellHook}
      echo 🥂 You are now in a shell for working on \"${v.component.package.name}\"
    '';
  }
  ))) configuredGrid.allComponents // configuredGrid.shells
