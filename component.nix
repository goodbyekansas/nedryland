pkgs:
rec {
  mkComponent =
    path: mkCombinedDeployment: parseConfig: mkDocs:
    let
      mkComponentInner = attrs'@{ name, subComponents ? { }, nedrylandType ? "component", ... }:
        let
          cleanedAttrs = builtins.removeAttrs attrs' [ "subComponents" ] // subComponents;
          attrs = (
            builtins.mapAttrs
              (name': value:
                let
                  value' =
                    if name' == "docs" &&
                      ! value ? _isNedrylandCombinedDocs &&
                      builtins.isAttrs value
                    then mkDocs value else value;
                in
                if value' ? _isNedrylandCombinedDocs then
                  value'.resolve (value'.name or name)
                else
                  value'
              )
              cleanedAttrs
          );
          component' = (attrs // {
            inherit name path nedrylandType;
            isNedrylandComponent = true;
            __toString = self: "Nedryland component: ${self.name}";
          } // (pkgs.lib.optionalAttrs (attrs ? deployment && attrs.deployment != { }) {
            # the deploy target is simply the sum of everything
            # in the deployment set
            deploy = mkCombinedDeployment "${name}-deploy" attrs.deployment;
          }));

          component = component';
          docsRequirement = (parseConfig {
            key = "docs";
            structure = { requirements = { "${component.nedrylandType}" = [ ]; }; };
          }
          ).requirements."${component.nedrylandType}";
        in
        assert pkgs.lib.assertMsg
          (docsRequirement != [ ] -> component ? docs && builtins.all
            (e: builtins.elem e (builtins.attrNames attrs.docs))
            docsRequirement)
          ''Projects config demands type "${component.nedrylandType}" to have at least: ${builtins.concatStringsSep ", " docsRequirement}.
          "${component.name}" has: ${builtins.concatStringsSep "," (builtins.attrNames attrs.docs or { })}.'';
        (component
          // {
          overrideAttrs = f: mkComponentInner (attrs' // (f component));
        });
    in
    mkComponentInner;

  mapComponentsRecursive = f:
    let
      recurse = path:
        let
          g =
            name: value:
            if ! builtins.isAttrs value || pkgs.lib.isDerivation value then value
            else
              recurse (path ++ [ name ]) (
                if value.isNedrylandComponent or false then f (path ++ [ name ]) value
                else value
              );
        in
        builtins.mapAttrs g;
    in
    recurse [ ];

  collectComponentsRecursive = set:
    if set.isNedrylandComponent or false then
      [ set ] ++ (builtins.concatMap collectComponentsRecursive (builtins.attrValues set))
    else if builtins.isAttrs set && !pkgs.lib.isDerivation set then
      builtins.concatMap collectComponentsRecursive (builtins.attrValues set)
    else
      [ ];
}
