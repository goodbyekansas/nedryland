{ nedryland, pkgs }:
(nedryland { inherit pkgs; }).mkProject {
  name = "dep-example-father";

  components = {}: { };

  baseExtensions = [
    ./extensions/mkfather.nix
  ];
}
