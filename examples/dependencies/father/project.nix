{ nedryland, pkgs }:
(nedryland { inherit pkgs; }).mkProject {
  name = "dep-example-father";

  components = _: { };

  baseExtensions = [
    ./extensions/mkfather.nix
  ];
}
