import (
  builtins.fetchGit {
    name = "nixpackages-20.03-beta";
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "refs/tags/20.03-beta"; # pinned because of https://github.com/NixOS/nixpkgs/issues/75941
  }
)
