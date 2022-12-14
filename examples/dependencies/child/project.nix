{ nedryland, pkgs }:
(nedryland { inherit pkgs; }).mkProject rec {
  name = "deps-example-child";
  dependencies = [ (import ../father/project.nix { inherit nedryland pkgs; }) ];
  components = { callFile }: {
    luke = callFile ./luke/luke.nix { };
  };
  baseExtensions = [
    # This extension is made using an extension in dependencies
    ./extensions/mkchild.nix
  ];
}
