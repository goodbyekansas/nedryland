{ pkgs, components, extraShells ? { } }:
let
  getAllPackages = components:
    let
      comp = if (builtins.isFunction components) then (components { }) else components;
    in
    [ ] ++
    (
      if builtins.hasAttr "package" comp then
        [ comp.package ]
      else
        builtins.map (c: getAllPackages c) (builtins.attrValues comp)
    );

  all = pkgs.mkShell {
    buildInputs = (getAllPackages components);
  };
in
builtins.mapAttrs
  (
    # TODO: Add support for nested components
    name: component:
      (
        let
          pkg = component.package;
          shellPkg = pkg.drvAttrs // {
            name = "${pkg.name}-shell";
            buildInputs = (pkg.shellInputs or [ ]) ++ (pkg.buildInputs  or [ ]);
            shellHook = ''
              echo 🏗️ Changing dir to \"${builtins.dirOf (builtins.toString component.path)}\"
              cd ${builtins.dirOf (builtins.toString component.path)}
              echo 🐚 Running shell hook for \"${name}\"
              ${pkg.shellHook or ""}
              echo 🥂 You are now in a shell for working on \"${name}\"
            '';
          };
        in
        pkgs.mkShell shellPkg
      )
  )
  components // extraShells // {
  inherit all;
}
