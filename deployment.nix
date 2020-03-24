{ pkgs }:
let
  k8sFunctions = import ./configs/k8sconfig.nix pkgs;
in
{
  mkStaticHTMLContainer = import ./utils/build-static-nginx.nix pkgs;
  mkK8sConfigStaticImage = k8sFunctions.static;
  mkK8sConfig = k8sFunctions.dynamic;
  mkDatabaseConfig = import ./configs/databaseconfig.nix;
  mkDeploymentConfig = import ./configs/deploymentconfig.nix;
  mkWindowsInstaller = {}: {};
  mkRPMPackage = {}: {};
  uploadFiles = files: {};
  deployFunction = { package }: {
    type = "function";
    derivation = { lomax, endpoint, port }: pkgs.stdenv.mkDerivation {
      name = "deploy-${package.name}";
      inputPackage = package;
      inherit lomax;
      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        $lomax/bin/lomax --address ${endpoint} --port ${builtins.toString port} register $inputPackage/bin/${package.name}.wasm $inputPackage/manifest.toml 2>&1 | tee $out/command-output
      '';
    };
  };
}
