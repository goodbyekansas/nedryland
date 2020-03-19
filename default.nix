{ projectName, defaultConfigFile, componentPaths }:
let
  mozilla = import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz);
  python_pkg_overlays = import ./overlays/python_packages.nix;
  pkgs = import (builtins.fetchGit {
    name = "nixpackages-20.03-beta";
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "refs/tags/20.03-beta"; # pinned because of https://github.com/NixOS/nixpkgs/issues/75941
  })
    {
      overlays =
        [
          mozilla
          python_pkg_overlays
        ];
    };

  k8sFunctions = import ./configs/k8sconfig.nix pkgs;
  #protos = import ./protocols/default.nix pkgs;  # TODO
  configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper projectName}_config";
  configContent = if configContentFromEnv != "" then configContentFromEnv else (
    if builtins.pathExists defaultConfigFile then builtins.readFile defaultConfigFile else "{}");
  base = {
    mkComponent = { package, deployment ? {}, docs ? null, pth ? builtins.toString ./. }: rec { inherit package deployment docs pth; };
    mkStaticHTMLContainer = import ./utils/build-static-nginx.nix pkgs;
    mkK8sConfigStaticImage = k8sFunctions.static;
    mkK8sConfig = k8sFunctions.dynamic;
    mkDatabaseConfig = import ./configs/databaseconfig.nix;
    mkDeploymentConfig = import ./configs/deploymentconfig.nix;
    theme = import ./theme/default.nix pkgs;
    #protos = protos.package;
    parseConfig = import ./nix/config.nix pkgs configContent (pkgs.lib.toUpper projectName);
  };

  allComponents = builtins.listToAttrs (builtins.map (pth: {
    name = builtins.baseNameOf (builtins.dirOf pth);
    value = {
      pth = builtins.toString pth;
      component =
        let
          c = pkgs.callPackage pth { inherit base; };
        in 
        c // {
          packageWithChecks = c.package.overrideAttrs (oldAttrs: {
            doCheck = true;
          });
        };
      };
  }) componentPaths );

in
  rec {
    all = builtins.map (v: v.component) (builtins.attrValues allComponents);
    package = builtins.map (component: component.package) all;
    packageWithChecks = builtins.map (component: component.packageWithChecks) all;
    deploymentConfigs = builtins.filter (c: c != null)
      (builtins.map (component: component.deployment) all);
    docs = pkgs.lib.foldl (x: y: x // y) {} (
      builtins.filter (d: d != {} && d != null)
      (builtins.map (component: component.docs) all));

    deploy =
        {
          local = pkgs.callPackage ./infra/local.nix {
            inherit base deploymentConfigs;
          };
          prod = pkgs.callPackage ./infra/prod.nix {
            inherit base deploymentConfigs;
          };
    };

    shells = {
      deploy = {
        local = pkgs.callPackage ./infra/local/shell.nix {
          deployment = deploy.local;
        };
        prod = pkgs.callPackage ./infra/prod/shell.nix {
          deployment = deploy.prod;
        };
      };
    };

    inherit allComponents;

  } // (builtins.mapAttrs (n: v: v.component) allComponents)
