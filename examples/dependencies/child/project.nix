(import ../../../default.nix { }).mkProject rec{
  name = "deps-example-child";
  dependencies = [ (import ../mother/project.nix) (import ../father/project.nix) ];
  components = { callFile }: {
    nooo = callFile ./clients/nooo/nooo.nix { parents = dependencies; };
  };
  baseExtensions = [
    # This extension is made using an extension in dependencies
    ./extensions/luke.nix
  ];
}
