pkgs:

{
  mkComponent =
    attrs@{ package, deployment ? { }, docs ? null, ... }:
    let
      comp = (
        attrs // {
          inherit package deployment docs;
          isNedrylandComponent = true;
          __toString = self: "Nedryland component: ${self.name or self.package.name}";
        }
      );
    in
    comp;

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


  initComponent = component: path: mkCombinedDeployment:
    # order is important here, components can set path manually
    ({ inherit path; } // {
      packageWithChecks =
        component.package.overrideAttrs (
          oldAttrs: {
            doCheck = true;

            # Python packages don't have a checkPhase, only an installCheckPhase
            doInstallCheck = true;
          } // (if component.package.stdenv.hostPlatform != component.package.stdenv.buildPlatform
            && oldAttrs.doCrossCheck or false then {
            preInstallPhases = [ "crossCheckPhase" ];
            crossCheckPhase = oldAttrs.checkPhase or "";
            nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ] ++ oldAttrs.checkInputs or [ ];
          } else { })
        );

      # the deploy target is simply the sum of everything
      # in the deployment set
      deploy = mkCombinedDeployment "${component.package.name}-deploy" component.deployment;
    } // component);
}
