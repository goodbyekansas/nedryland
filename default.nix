let
  pkgs = import ./nixpkgs.nix
    {
      overlays =
        [
          # rust
          (import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz))

          # extra pip packages
          (import ./overlays/python_packages.nix)
        ];
    };
in
rec {
  getDeployments = { components, type }: builtins.map (c: c.derivation or {}) (
    builtins.filter (c: c.type or "" == type) (
      pkgs.lib.flatten (
        builtins.map (c: (builtins.attrValues c.deployment)) (
          builtins.filter (c: builtins.hasAttr "deployment" c) (builtins.attrValues components)
        )
      )
    )
  );

  getFunctionDeployments = args@{ components, lomax, endpoint ? "tcp://[::1]", port ? 1939 }: builtins.map (
    drv:
      drv { inherit lomax endpoint port; }
  ) (
    getDeployments { inherit components; type = "function"; }
  );

  # TODO find a better way of dealing with protobuf
  mkProject = { name, configFile, protoLocation }:
    let
      configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper name}_config";
      configContent = if configContentFromEnv != "" then configContentFromEnv else (
        if builtins.pathExists configFile then builtins.readFile configFile else "{}"
      );

      base = {
        mkComponent = import ./mkcomponent.nix pkgs protoLocation;
        mkFunction = import ./mkfunction.nix base;
        mkClient = import ./mkclient.nix base;
        mkService = import ./mkservice.nix base;
        deployment = pkgs.callPackage ./deployment.nix {};
        theme = import ./theme/default.nix pkgs;
        parseConfig = import ./config.nix pkgs configContent (pkgs.lib.toUpper name);
        languages = pkgs.callPackage ./languages { inherit base; };
      };
    in
      {
        declareComponent = path: dependencies@{ ... }:
          let
            c = pkgs.callPackage path ({ inherit base; } // dependencies);
          in
            c // {
              inherit path;
              packageWithChecks = c.package.overrideAttrs (
                oldAttrs: {
                  doCheck = true;
                }
              );
            };

        mkGrid = { components, deploy }:
          let
            allComponents = (builtins.attrValues components);
          in
            rec {
              inherit deploy;

              package = builtins.map (component: component.package) allComponents;
              packageWithChecks = builtins.map (component: component.packageWithChecks) allComponents;
              deploymentConfigs = builtins.filter (c: c != null)
                (builtins.map (component: component.deployment) allComponents);
              docs = pkgs.lib.foldl (x: y: x // y) {} (
                builtins.filter (d: d != {} && d != null)
                  (builtins.map (component: component.docs) allComponents)
              );
            } // components;

        mkShells = { components, extraShells ? {} }: pkgs.callPackage ./shell.nix { inherit components extraShells; };
      };
}
