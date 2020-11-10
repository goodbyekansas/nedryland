pkgs: attrs@{ package, deployment ? { }, docs ? null, ... }:
let
  comp = (
    attrs // {
      inherit package deployment docs;
      isNedrylandComponent = true;
    }
  );
in
comp
