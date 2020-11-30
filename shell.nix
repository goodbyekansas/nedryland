{ pkgs, components, extraShells ? { } }:
let
  getAllPackages = components:
    [ ]
    ++ (
      if components.isNedrylandComponent or false then
        [ components.package ]
      else
        builtins.map (c: getAllPackages c) (builtins.filter (c: builtins.isAttrs c) (builtins.attrValues components))
    );

  all = pkgs.mkShell {
    buildInputs = (getAllPackages components);
  };
in
pkgs.lib.mapAttrsRecursiveCond
  (current: !(current.isNedrylandComponent or false))
  (
    attrName: component:
      (
        let
          pkg = component.packageWithChecks;
          name = component.name or (builtins.concatStringsSep "." attrName);
          shellPkg = pkg.drvAttrs // {
            name = "${pkg.name}-shell";
            nativeBuildInputs = (pkg.shellInputs or [ ]);
            inputsFrom = [ pkg ];
            componentDir = builtins.toString component.path;
            shellHook = ''
              componentDir="$componentDir"
              if [ -f "$componentDir" ]; then
                componentDir=$(dirname "$componentDir")
              fi

              echo ⛑ Changing dir to \"$componentDir\"
              cd "$componentDir"
              echo 🐚 Running shell hook for \"${name}\"
              ${pkg.shellHook or ""}
              echo 🥂 You are now in a shell for working on \"${name}\"
            '';
          };
        in
        (pkg.crossSystem or pkgs).mkShell shellPkg # TODO document crossSystem or find a better way
      )
  )
  components // extraShells // {
  inherit all;
}
