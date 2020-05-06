{ pkgs, components, extraShells ? { } }:
let
  all = pkgs.mkShell {
    buildInputs = builtins.map (c: c.package) (builtins.attrValues components);
  };
in
builtins.mapAttrs
  (
    name: component:
      (
        component.package.overrideAttrs
          (
            oldAttrs: {
              shellHook = ''
                echo 🏗️ Changing dir to \"${builtins.dirOf (builtins.toString component.path)}\"
                cd ${builtins.dirOf (builtins.toString component.path)}
                echo 🐚 Running shell hook for \"${name}\"
                ${oldAttrs.shellHook}
                echo 🥂 You are now in a shell for working on \"${name}\"
              '';
            }
          )
      )
  ) components // extraShells // {
  inherit all;
}
