let
  pkgsUnstable = (import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/fdc7e050b04fc88951468ff21b019a97b7e6412f.tar.gz)) {};
in
self: super:
{
    terraform_0_13 = pkgsUnstable.terraform_0_13;
}
