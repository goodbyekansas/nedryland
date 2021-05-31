pkgs:
rec {

  enableChecksOnComponent = component:
    builtins.mapAttrs
      (n: v:
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
        else v)
      component;

  mkComponent =
    enableChecks: path: mkCombinedDeployment:
    let
      mkComponentInner = attrs'@{ name, subComponents ? { }, ... }:
        let
          attrs = builtins.removeAttrs attrs' [ "subComponents" ] // subComponents;
          component' =
            (attrs // {
              inherit name path;
              isNedrylandComponent = true;
              __toString = self: "Nedryland component: ${self.name}";
            } // (if attrs ? deployment && attrs.deployment != { } then {
              # the deploy target is simply the sum of everything
              # in the deployment set
              deploy = mkCombinedDeployment "${name}-deploy" attrs.deployment;
            } else { }));

          component = if enableChecks then enableChecksOnComponent component' else component';
        in
        (component // {
          allTargets = builtins.attrValues (pkgs.lib.filterAttrs (n: x: pkgs.lib.isDerivation x) component);
          overrideAttrs = f: mkComponentInner (attrs' // (f component));
        });
    in
    mkComponentInner;

  mapComponentsRecursive = f: set:
    let
      recurse = path: set:
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
        builtins.mapAttrs g set;
    in
    recurse [ ] set;

  collectComponentsRecursive = set:
    if set.isNedrylandComponent or false then
      [ set ] ++ (builtins.concatMap collectComponentsRecursive (builtins.attrValues set))
    else if builtins.isAttrs set && !pkgs.lib.isDerivation set then
      builtins.concatMap collectComponentsRecursive (builtins.attrValues set)
    else
      [ ];
}
