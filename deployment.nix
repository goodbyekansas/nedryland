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
  deployFunction = { package }: {};
}
