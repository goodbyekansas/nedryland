pkgs:
let
  enableChecksOnComponent = component:
    builtins.mapAttrs
      (n: v:
        if pkgs.lib.isDerivation v then
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
in
{
  mkComponent =
    enableChecks: path: mkCombinedDeployment: attrs@{ name, ... }:
    let
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
      allTargets = pkgs.lib.unique (builtins.attrValues (pkgs.lib.filterAttrs (n: x: pkgs.lib.isDerivation x) component));
    });

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
}
