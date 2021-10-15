(import ../../../default.nix { }).mkProject {
  name = "dep-example-father";

  components = {}: { };

  baseExtensions = [
    ./extensions/darth.nix
  ];
}
