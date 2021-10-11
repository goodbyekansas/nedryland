pkgs:
rec {
  enableChecksOnComponent =
    builtins.mapAttrs
      (_: v:
        if pkgs.lib.isDerivation v && v ? overrideAttrs then
          v.overrideAttrs
            (oldAttrs: {
              doCheck = true;

              # Python packages don't have a checkPhase, only an installCheckPhase
              doInstallCheck = true;
            } // (if v.stdenv.hostPlatform != v.stdenv.buildPlatform && oldAttrs.doCrossCheck or false then {
              preInstallPhases = [ "crossCheckPhase" ];
              crossCheckPhase = oldAttrs.checkPhase or "";
              nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ] ++ oldAttrs.checkInputs or [ ];
            } else { }))
        else v);

  mkComponent =
    enableChecks: path: mkCombinedDeployment: parseConfig:
    let
      mkComponentInner = attrs'@{ name, subComponents ? { }, nedrylandType ? "component", ... }:
        let
          attrs = builtins.removeAttrs attrs' [ "subComponents" ] // subComponents;
          component' =
            (attrs // {
              inherit name path nedrylandType;
              isNedrylandComponent = true;
              __toString = self: "Nedryland component: ${self.name}";
            } // (if attrs ? deployment && attrs.deployment != { } then {
              # the deploy target is simply the sum of everything
              # in the deployment set
              deploy = mkCombinedDeployment "${name}-deploy" attrs.deployment;
            } else { }) // (if attrs ? docs then {
              docs = pkgs.lib.mapAttrs
                (_: doc:
                  if pkgs.lib.isDerivation doc then doc
                  else doc.package)
                attrs.docs;
            } else { }));

          component = if enableChecks then enableChecksOnComponent component' else component';
          docsRequirement = (parseConfig {
            key = "docs";
            structure = { requirements = { "${component.nedrylandType}" = [ ]; }; };
          }
          ).requirements."${component.nedrylandType}";
        in
        assert pkgs.lib.assertMsg
          (docsRequirement != [ ] -> component ? docs && builtins.all
            (e: builtins.elem e (builtins.attrNames component.docs))
            docsRequirement)
          ''Projects config demands type "${component.nedrylandType}" to have at least: ${builtins.concatStringsSep ", " docsRequirement}.
          "${component.name}" has: ${builtins.concatStringsSep "," (builtins.attrNames component.docs or { })}.'';
        (component
          // {
          allTargets = builtins.attrValues (pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) component);
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
