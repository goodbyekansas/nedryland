{
  description = "Example project demonstrating documentation capabilities.";

  inputs = {
    pkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { pkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs' = pkgs.legacyPackages.${system};
        nedryland = import ../../default.nix;
        project = import ./project.nix {
          inherit nedryland;
          pkgs = pkgs';
        };
      in
      {
        packages = project.matrix // {
          # This make `$nix build` (without arguments) result in a linkfarm of all components.
          default = project.components;
        };
        devShells = project.shells;
      });
}
