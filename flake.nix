{
  description = "Nedryland is a collection of utilities and a build system for declaring, building and deploying microservice solutions.";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    # Use the same nixpkgs
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { nixpkgs, flake-utils, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ gitignore.overlay ]; };
      in
      {
        lib = import ./. { nixpkgs = pkgs; };
      }
    );
}
