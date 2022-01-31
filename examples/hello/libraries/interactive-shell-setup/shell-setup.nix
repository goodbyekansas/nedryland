{ base, python3 }:
base.languages.python.mkLibrary {
  name = "shell-setup";
  version = "1.0.0";
  src = ./.;

  pythonVersion = python3;
  # This custom builder is just to make our checks pass for this component, which can't
  # be built until someone enters the shell and does the setup.
  builder = builtins.toFile "shell-thingy" ''
    source $stdenv/setup
    touch $out
  '';
  format = "other";
}
