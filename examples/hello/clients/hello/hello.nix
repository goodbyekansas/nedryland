{ base, pkgs, numpyWrapper }:
# base and pkgs are given by Nedryland,
# everything else has to be provided in `project.nix`
base.languages.python.mkClient {
  name = "hello";
  version = "0.1.0";
  src = ./.;
  pythonVersion = pkgs.python3;
  # Here we don't use pp with numpyWrapper since it's our own
  # package and not part of the python version packages.
  buildInputs = (pp: [ numpyWrapper ]);
}
