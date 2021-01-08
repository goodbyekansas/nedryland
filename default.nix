let
  sources = import ./nix/sources.nix;
  pkgs = with
    {
      overlay = _: pkgs:
        {
          niv = import sources.niv { };
        };
    };
    import sources.nixpkgs
      {
        overlays = [
          overlay

          # rust
          (import sources.nixpkgs-mozilla)

          # extra pip packages
          (import ./overlays/python_packages.nix)

          # comment here
          (import ./overlays/wasmer.nix)

          # more recent Wasi lib C (default was 2019)
          (import ./overlays/wasilibc.nix)
        ];
        config = { };
      };
in
rec {
  nixpkgs = pkgs;
  docs = pkgs.stdenv.mkDerivation rec {
    name = "nedryland-docs";
    src = builtins.path { inherit name; path = ./docs; };
    buildInputs = [ pkgs.mdbook ];
    buildPhase = "mdbook build --dest-dir book";
    installPhase = ''
      mkdir -p $out
      cp -r book/. $out
    '';
  };

  mkProject = { name, configFile, baseExtensions ? [ ], projectDependencies ? [ ] }:
    let
      configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper name}_config";
      configContent =
        if configContentFromEnv != "" then configContentFromEnv else
        (
          if builtins.pathExists configFile then builtins.readFile configFile else "{}"
        );
      base = {
        inherit sources;
        mkComponent = import ./mkcomponent.nix pkgs;
        mkClient = import ./mkclient.nix base;
        mkService = import ./mkservice.nix base;
        extend = pkgs.callPackage ./extend.nix { };
        deployment = pkgs.callPackage ./deployment.nix { inherit base; };
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
          # Combine all extensions into one dictionary that we can merge with base
          combinedBaseExtensions: currentBaseExtension: pkgs.lib.recursiveUpdate combinedBaseExtensions (currentBaseExtension { base = (pkgs.lib.recursiveUpdate combinedBaseExtensions base); inherit pkgs; })
        )
        { }
        allBaseExtensions;
      extendedBase = pkgs.lib.recursiveUpdate combinedBaseExtensions base;
    in
    {
      mkCombinedDeployment = base.deployment.mkCombinedDeployment;
      declareComponent = path: dependencies@{ ... }:
        let
          c = pkgs.callPackage path ({ base = extendedBase; } // dependencies);
          setupComponents = attrs:
            if attrs.isNedrylandComponent or false then
            # order is important here, components can set path manually
              ({ inherit path; } // {
                packageWithChecks =
                  attrs.package.overrideAttrs (
                    oldAttrs: {
                      doCheck = true;

                      # Python packages don't have a checkPhase, only an installCheckPhase
                      doInstallCheck = true;
                    } // (if attrs.package.stdenv.hostPlatform != attrs.package.stdenv.buildPlatform && oldAttrs.doCrossCheck or false then {
                      preInstallPhases = [ "crossCheckPhase" ];
                      crossCheckPhase = oldAttrs.checkPhase;
                      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ oldAttrs.checkInputs;
                    } else { })
                  );

                # the deploy target is simply the sum of everything
                # in the deployment set
                deploy = base.deployment.mkCombinedDeployment "${attrs.package.name}-deploy" attrs.deployment;
              } // attrs)
            else
              (builtins.mapAttrs (n: v: if builtins.isAttrs v then setupComponents v else v) attrs);
        in
        setupComponents c;

      mkGrid = { components, deploy ? { }, extraShells ? { }, lib ? { } }:
        let
          gatherComponents = components:
            builtins.foldl'
              (
                accumulator: current: accumulator ++ (
                  if current.isNedrylandComponent or false then
                    [ current ]
                  else
                    gatherComponents current
                )
              )
              [ ]
              (builtins.filter builtins.isAttrs (builtins.attrValues components))
          ;
          allComponents = components;
          componentsList = gatherComponents allComponents;
        in
        {
          inherit baseExtensions lib;
          grid = rec {
            inherit deploy;

            package = builtins.map (component: component.package) componentsList;
            packageWithChecks = builtins.map (component: component.packageWithChecks) componentsList;
            deploymentConfigs =
              builtins.filter
                (c: c != null)
                (builtins.map (component: component.deployment) componentsList);
            docs =
              pkgs.lib.foldl
                (x: y: x // y)
                { }
                (
                  builtins.filter
                    (d: d != { } && d != null)
                    (builtins.map (component: component.docs) componentsList)
                );
          } // allComponents;
          shells = pkgs.callPackage ./shell.nix { components = allComponents; inherit extraShells; };
        };
    };
}
