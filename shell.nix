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
          shellPkg = pkg.drvAttrs // rec {
            name = "${pkg.name}-shell";

            hook = pkg.shellHook or "";
            nativeBuildInputs = (pkg.shellInputs or [ ]);

            # we will get double shellhooks if we do not
            # remove this here
            inputsFrom = [ (builtins.removeAttrs pkg [ "shellHook" ]) ];

            componentDir = builtins.toString component.path;
            shellHook = ''
              componentDir="$componentDir"
              if [ -f "$componentDir" ]; then
                componentDir=$(dirname "$componentDir")
              fi

              echo ⛑ Changing dir to \"$componentDir\"
              cd "$componentDir"
              echo 🐚 Running shell hook for \"${name}\"
              ${hook}
              echo 🥂 You are now in a shell for working on \"${name}\"
            '';
          };
        in
        pkgs.mkShell.override
          {
            stdenv = pkg.stdenv;
          }
          shellPkg
      )
  )
  components // extraShells // {
  inherit all;
}
