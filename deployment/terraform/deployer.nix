{ base, pkgs }:
base.languages.python.mkClient {
  name = "terraform-deployer";
  version = "0.1.0";
  src = ./.;
  pythonVersion = pkgs.python3;
}
