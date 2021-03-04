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
          (import sources.rust)

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
{

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

  ci = pkgs.runCommand "ci-scripts"
    {
      nixpkgsFmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
      diff = "${pkgs.diffutils}/bin/diff";
      # Pointless to do this on a remote machine.
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      n=$out/bin/nixfmt
      mkdir -p "$(dirname "$n")"
      substituteAll ${./ci/nix-fmt.bash} $n
      chmod +x "$n"
    '';

  mkProject =
    attrs@{ name
    , components
    , baseExtensions ? [ ]
    , extraShells ? { }
    , configFile ? null
    , lib ? { }
    , dependencies ? [ ]
    , ...
    }:
    let
      componentFns = import ./component.nix pkgs;
      mapComponentsRecursive = componentFns.mapComponentsRecursive;

      base = {
        inherit sources mapComponentsRecursive callFile;
        mkComponent = componentFns.mkComponent;
        mkClient = import ./mkclient.nix base;
        mkService = import ./mkservice.nix base;
        extend = pkgs.callPackage ./extend.nix { };
        deployment = pkgs.callPackage ./deployment.nix { inherit base; };
        theme = import ./theme/default.nix pkgs;
        parseConfig = import ./config.nix pkgs configContent (pkgs.lib.toUpper name);
        languages = pkgs.callPackage ./languages { inherit base; };
      };

      callFile = path: attrs: pkgs.lib.makeOverridable
        (
          attrs:
          let
            f = import path;
            args = builtins.functionArgs f;
            # The result from calling the function specified by callFile
            # is not guaranteed to be an actual component. It could just be a set
            # or a string which is ok.
            result = (f
              (
                (builtins.intersectAttrs args pkgs)
                // (builtins.intersectAttrs args resolvedComponents)
                // (builtins.intersectAttrs args {
                  base = extendedBase;
                })
                // attrs
              )
            );
          in
          if result.isNedrylandComponent or false then
            componentFns.initComponent result path base.deployment.mkCombinedDeployment
          else
            result
        )
        attrs;

      appliedAttrs =
        builtins.mapAttrs
          (n: v:
            if builtins.isFunction v then
              v (builtins.intersectAttrs (builtins.functionArgs v) base)
            else
              v)
          attrs;

      configContentFromEnv = builtins.getEnv "${pkgs.lib.toUpper appliedAttrs.name}_config";
      configContent =
        if configContentFromEnv != "" then configContentFromEnv else
        (
          if appliedAttrs.configFile != null
            && builtins.pathExists appliedAttrs.configFile then
            builtins.readFile appliedAttrs.configFile
          else "{}"
        );

      projectBaseExtensions = (builtins.foldl'
        (
          combinedBaseExtensions: currentBaseExtension:
            let
              extFn = import currentBaseExtension;
              args = builtins.functionArgs extFn;
            in
            pkgs.lib.recursiveUpdate combinedBaseExtensions (
              extFn (
                builtins.intersectAttrs args resolvedComponents // {
                  base = (pkgs.lib.recursiveUpdate combinedBaseExtensions baseWithDependencies);
                  inherit pkgs;
                }
              )
            )
        )
        { }
        appliedAttrs.baseExtensions or [ ]
      );

      dependenciesBaseExtensions = (
        builtins.foldl'
          pkgs.lib.recursiveUpdate
          { }
          (builtins.map (pd: pd.baseExtensions) appliedAttrs.dependencies or [ ])
      );
      baseWithDependencies = pkgs.lib.recursiveUpdate dependenciesBaseExtensions base;
      extendedBase = pkgs.lib.recursiveUpdate projectBaseExtensions baseWithDependencies;

      resolvedComponents = appliedAttrs.components;

      allTargets = pkgs.lib.zipAttrs (
        builtins.map
          (
            comp: pkgs.lib.filterAttrs
              (
                name: value: pkgs.lib.isDerivation value
              )
              comp
          )
          (pkgs.lib.collect (value: value.isNedrylandComponent or false) resolvedComponents)
      );

      extraTargets = builtins.mapAttrs
        (
          name: value: if builtins.isFunction value then value resolvedComponents else value
        )
        (builtins.removeAttrs appliedAttrs [
          "components"
          "extraShells"
          "lib"
          "baseExtensions"
          "configFile"
          "name"
          "dependencies"
        ]);

    in
    rec {
      name = appliedAttrs.name;
      lib = appliedAttrs.lib or { };

      components = resolvedComponents;
      targets = allTargets // extraTargets;
      matrix = components // targets;

      baseExtensions = projectBaseExtensions;
      nixpkgs = pkgs;
      nixpkgsPath = sources.nixpkgs;
      mkCombinedDeployment = base.deployment.mkCombinedDeployment;

      shells = pkgs.callPackage ./shell.nix {
        inherit mapComponentsRecursive;
        extraShells = appliedAttrs.extraShells or { };
        components = resolvedComponents;
      };
    };
}
