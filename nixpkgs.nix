import (
  builtins.fetchGit {
    name = "nixpackages-20.03";
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "refs/tags/20.03";
  }
)
