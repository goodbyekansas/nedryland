{
  description = "Nedryland is a collection of utilities and a build system for declaring, building and deploying microservice solutions.";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          internalNedryland = (import ./default.nix { inherit pkgs; });
        in
        {
          lib = import ./.;
          packages = {
            inherit (internalNedryland) docs checks;
            default = pkgs.linkFarm
              "all"
              (pkgs.lib.mapAttrsToList
                (name: path: { inherit name path; })
                { inherit (internalNedryland) docs checks; });
          };
          apps = {
            checks = rec {
              type = "app";
              program = all.program;

              nixfmt = {
                type = "app";
                program = "${internalNedryland.checks}/bin/nixfmt";
              };
              shellcheck = {
                type = "app";
                program = "${internalNedryland.checks}/bin/shellcheck";
              };
              nix-lint = {
                type = "app";
                program = "${internalNedryland.checks}/bin/nix-lint";
              };
              all = {
                type = "app";
                program = "${internalNedryland.checks}/bin/check";
              };
              actionlint = {
                type = "app";
                program = "${internalNedryland.checks}/bin/actionlint";
              };
            };
          };

          devShells.docs = internalNedryland.docs;
          checks.default = builtins.derivation {
            inherit system;
            name = "all-tests";
            builder = "${pkgs.bash}/bin/bash";
            args = [ "-c" ''${pkgs.coreutils}/bin/touch $out'' ];
            tests = builtins.filter (x: x != { })
              (import ./test.nix {
                inherit pkgs;
              }).all;
          };
        }
      );
}
