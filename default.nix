let
  pkgs =
    import ./nixpkgs.nix {
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
  # import another nedryland project
  importProject = { name, url, rev ? null, ref ? "master", pathOverrideEnvVar ? "${pkgs.lib.toUpper name}_PATH" }:
    import (
      if builtins.getEnv pathOverrideEnvVar != "" then
        (builtins.getEnv "PWD" + "/${builtins.getEnv pathOverrideEnvVar}/project.nix")
      else
        builtins.fetchGit {
          inherit name url rev ref;
        } + "/project.nix"
    );

  mkProject = { name, configFile, baseExtensions ? [ ], projectDependencies ? [ ] }:
    let
      configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper name}_config";
      configContent =
        if configContentFromEnv != "" then configContentFromEnv else (
          if builtins.pathExists configFile then builtins.readFile configFile else "{}"
        );
      base = {
        mkComponent = import ./mkcomponent.nix pkgs;
        mkClient = import ./mkclient.nix base;
        mkService = import ./mkservice.nix base;
        extend = pkgs.callPackage ./extend.nix { };
        deployment = pkgs.callPackage ./deployment.nix { };
        theme = import ./theme/default.nix pkgs;
        parseConfig = import ./config.nix pkgs configContent (pkgs.lib.toUpper name);
        languages = pkgs.callPackage ./languages { inherit base; };
      };
      allBaseExtensions = (
        builtins.foldl'
          (x: y: x ++ y) [ ]
          (
            builtins.map (pd: pd.baseExtensions) projectDependencies
          )
      ) ++ baseExtensions;
      combinedBaseExtensions = builtins.foldl'
        (
          left: right: pkgs.lib.recursiveUpdate left (right { inherit base pkgs; })
        )
        { }
        allBaseExtensions;
      extendedBase = pkgs.lib.recursiveUpdate combinedBaseExtensions base;
    in
    {
      declareComponent = path: dependencies@{ ... }:
        let
          c = pkgs.callPackage path ({ base = extendedBase; } // dependencies);
        in
        c // {
          inherit path;
          packageWithChecks =
            c.package.overrideAttrs (
              oldAttrs: {
                doCheck = true;

                # Python packages don't have a checkPhase, only an installCheckPhase
                doInstallCheck = true;
              }
            );
        };

      mkGrid = { components, deploy, extraShells ? { }, lib ? { } }:
        let
          allComponents = (builtins.attrValues components);
        in
        {
          inherit baseExtensions lib;
          grid = rec {
            inherit deploy;

            package = builtins.map (component: component.package) allComponents;
            packageWithChecks = builtins.map (component: component.packageWithChecks) allComponents;
            deploymentConfigs =
              builtins.filter
                (c: c != null)
                (builtins.map (component: component.deployment) allComponents);
            docs =
              pkgs.lib.foldl
                (x: y: x // y)
                { }
                (
                  builtins.filter
                    (d: d != { } && d != null)
                    (builtins.map (component: component.docs) allComponents)
                );
          } // components;
          shells = pkgs.callPackage ./shell.nix { inherit components extraShells; };
        };
    };
}
