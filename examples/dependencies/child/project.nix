(import ../../../default.nix { }).mkProject rec{
  name = "deps-example-child";
  dependencies = [ (import ../father/project.nix) ];
  components = { callFile }: {
    luke = callFile ./luke/luke.nix { };
  };
  baseExtensions = [
    # This extension is made using an extension in dependencies
    ./extensions/mkchild.nix
  ];
}
