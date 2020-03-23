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
{
  # TODO find a better way of dealing with protobuf
  mkProject = { name, configFile, protoLocation }:
    let
      configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper name}_config";
      configContent = if configContentFromEnv != "" then configContentFromEnv else (
        if builtins.pathExists configFile then builtins.readFile configFile else "{}"
      );

      # gbk-pipeline specific functionality
      base = {
        mkComponent = import ./mkcomponent.nix pkgs protoLocation;
        mkFunction = import ./mkfunction.nix base;
        mkClient = import ./mkclient.nix base;
        deployment = pkgs.callPackage ./deployment.nix {};
        theme = import ./theme/default.nix pkgs;
        parseConfig = import ./config.nix pkgs configContent (pkgs.lib.toUpper name);
        languages = pkgs.callPackage ./languages { inherit base; };
      };
    in
      {
        declareComponent = path: { dependencies ? {} }:
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

        mkGrid = { components }:
          let
            allComponents = (builtins.attrValues components);
          in
            rec {
              inherit components; # Find a better way to communicate this with the shells!

              package = builtins.map (component: component.package) allComponents;
              packageWithChecks = builtins.map (component: component.packageWithChecks) allComponents;
              deploymentConfigs = builtins.filter (c: c != null)
                (builtins.map (component: component.deployment) allComponents);
              docs = pkgs.lib.foldl (x: y: x // y) {} (
                builtins.filter (d: d != {} && d != null)
                  (builtins.map (component: component.docs) allComponents)
              );

              deploy =
                {
                  local = pkgs.callPackage ./infra/local.nix {
                    inherit deploymentConfigs base;
                  };
                  prod = pkgs.callPackage ./infra/prod.nix {
                    inherit deploymentConfigs base;
                  };
                };

            } // components;

        mkShells = { components, extraShells ? {} }: import ./shell.nix { inherit components extraShells; };
      };
}
