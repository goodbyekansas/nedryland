(import ../../../default.nix { }).mkProject {
  name = "dep-example-father";

  components = {}: { };

  baseExtensions = [
    ./extensions/mkfather.nix
  ];
}
