{ pkgs, components, extraShells ? { } }:
let
  getAllPackages = components:
    [ ] ++
    (
      if builtins.hasAttr "package" components then
        [ components.package ]
      else
        builtins.map (c: getAllPackages c) (builtins.attrValues components)
    );

  all = pkgs.mkShell {
    buildInputs = (getAllPackages components);
  };
in
builtins.mapAttrs
  (
    name: component:
      (
        let pkg = component.package.overrideAttrs (
          oldAttrs: {
            shellHook = ''
              echo 🏗️ Changing dir to \"${builtins.dirOf (builtins.toString component.path)}\"
              cd ${builtins.dirOf (builtins.toString component.path)}
              echo 🐚 Running shell hook for \"${name}\"
              ${oldAttrs.shellHook}
              echo 🥂 You are now in a shell for working on \"${name}\"
            '';
          }
        );
        in
        pkgs.mkShell {
          name = "${pkg.name}-shell";
          inputsFrom = [ pkg ];
          buildInputs = pkg.shellInputs;
        }
      )
  )
  components // extraShells // {
  inherit all;
}
