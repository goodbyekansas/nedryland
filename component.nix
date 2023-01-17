pkgs: mkCombinedDeployment: parseConfig:
rec {
  mkComponentSet = mkComponent: name: nedrylandComponents:
    mkComponent
      ({
        inherit name;
        nedrylandType = "component-set";
      } // nedrylandComponents);

  mkComponent =
    path:
    let
      mkComponentInner = attrs@{ name, nedrylandType ? "component", ... }:
        let
          component =
            (attrs // {
              inherit name path nedrylandType;
            } // (pkgs.lib.optionalAttrs (attrs ? deployment && attrs.deployment != { }) {
              # the deploy target is simply the sum of everything
              # in the deployment set
              deploy = mkCombinedDeployment "${name}-deploy" attrs.deployment;
              deployment = attrs.deployment //
                (pkgs.linkFarm
                  "${name}-deployment"
                  (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) attrs.deployment));
            }) // (pkgs.lib.optionalAttrs (attrs ? docs && !pkgs.lib.isDerivation attrs.docs) {
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
          //
          (pkgs.linkFarm
            name
            (pkgs.lib.mapAttrsToList
              (name: path: { inherit name path; })
              (pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) component)))
          // {
          isNedrylandComponent = true;
          overrideAttrs = f: mkComponentInner (attrs // (f component));
          override = mkComponentInner;
          componentAttrs = component;
          nedrylandComponents = pkgs.lib.filterAttrs (_: c: c.isNedrylandComponent or false) component;
        });
    in
    mkComponentInner;

  mapComponentsRecursive = f:
    let
      recurse = path:
        let
          g =
            name: value:
            if value.isNedrylandComponent or false then
              recurse (path ++ [ name ]) (f (path ++ [ name ]) value)
            else
              value;
        in
        builtins.mapAttrs g;
    in
    recurse [ ];

  collectComponentsRecursive =
    let
      recurse = path:
        let
          g =
            name: value:
            if value.isNedrylandComponent or false then
              [
                ({
                  accessPath = (path ++ [ name ]);
                } // value)
              ] ++ (recurse (path ++ [ name ]) value)
            else
              [ ];
        in
        set:
        builtins.concatMap (name: g name (builtins.getAttr name set)) (builtins.attrNames set);
    in
    recurse [ ];
}
