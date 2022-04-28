pkgs:
rec {
  mkComponent =
    path: mkCombinedDeployment: parseConfig:
    let
      mkComponentInner = attrs'@{ name, subComponents ? { }, nedrylandType ? "component", ... }:
        let
          attrs = builtins.removeAttrs attrs' [ "subComponents" ] // subComponents;
          component' =
            (attrs // {
              inherit name path nedrylandType;
              isNedrylandComponent = true;
              __toString = self: "Nedryland component: ${self.name}";
            } // (pkgs.lib.optionalAttrs (attrs ? deployment && attrs.deployment != { }) {
              # the deploy target is simply the sum of everything
              # in the deployment set
              deploy = mkCombinedDeployment "${name}-deploy" attrs.deployment;
            }) // (pkgs.lib.optionalAttrs (attrs ? docs) {
              # the docs target is a symlinkjoin of all sub-derivations
              docs =
                let
                  resolvedDocDrvs = builtins.mapAttrs
                    (key: func: (func.docfunction name key))
                    (pkgs.lib.filterAttrs (_: v: builtins.isAttrs v && v ? docfunction) attrs.docs);
                  attrsWithResolvedDocDrvs = attrs.docs // resolvedDocDrvs;
                in
                pkgs.symlinkJoin {
                  name = "${name}-docs";
                  paths = builtins.attrValues resolvedDocDrvs ++ (builtins.filter pkgs.lib.isDerivation (builtins.attrValues attrs.docs));
                  passthru = attrsWithResolvedDocDrvs;
                  postBuild = ''
                    mkdir -p $out/share/doc/${name}/
                    echo '${builtins.toJSON attrsWithResolvedDocDrvs}' > $out/share/doc/${name}/metadata.json
                  '';
                };
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
