pkgs: project:
pkgs.stdenv.mkDerivation {
  name = "test-nested-components";
  phases = [ "checkNestedPhase" ];
  nativeBuildInputs = project.matrix.all;
  checkNestedPhase = ''
    touch $out
    if [[ ! "''${nativeBuildInputs[*]}" =~ "hello-nested" ]]; then
      echo "ERROR: The \"all\" target in the \"hello\" project does \
    not contain the expected \"hello-nested\" component".
      exit 1
    fi
  '';
}
