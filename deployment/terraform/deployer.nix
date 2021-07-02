{ base, pkgs }:
base.languages.python.mkClient {
  name = "terraform-deployer";
  version = "1.0.0";
  src = ./.;
  pythonVersion = pkgs.python3;
}
