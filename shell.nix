{ pkgs, components, mapComponentsRecursive, extraShells ? { } }:
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
mapComponentsRecursive
  (
    attrName: component:
      (
        let
          # TODO: replace all derivations with our own shells (currently only packageWithChecks)
          pkg = component.packageWithChecks;
          componentName = component.name or (builtins.concatStringsSep "." attrName);
          componentAttrs = builtins.removeAttrs component [ "package" "packageWithChecks" "deployment" "deploy" ];
          shellPkg = pkg.drvAttrs // rec {
            name = "${componentName}-shell";

            nativeBuildInputs = (pkg.shellInputs or [ ]);
            passthru = componentAttrs;
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
              echo 🐚 Running shell hook for \"${componentName}\"
              ${pkg.shellHook or ""}
              echo 🥂 You are now in a shell for working on \"${componentName}\"
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
