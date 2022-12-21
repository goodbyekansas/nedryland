{
  description = "Example project demonstrating project dependencies.";

  inputs = {
    pkgs.url = github:NixOS/nixpkgs/nixos-22.11;
  };

  outputs = { pkgs, ... }:
    let
      # TODO: not necessarily
      system = "x86_64-linux";

      pkgs' = pkgs.legacyPackages."${system}";
      nedryland = import ../../../default.nix;
      project = import ./project.nix {
        inherit nedryland;
        pkgs = pkgs';
      };
    in
    {
      packages."${system}" = project.matrix // {
        default = project.all;
      };
      devShells."${system}" = project.shells;
    };
}