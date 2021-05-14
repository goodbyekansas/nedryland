let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf/project.nix;
    hello = import ./examples/hello/project.nix;
    deployment = import ./deployment/project.nix;
  };

  mappedTests = builtins.mapAttrs
    (
      name: project: (
        project.override { enableChecks = true; }
      ).matrix.all
    )
    tests;

  pkgs = tests.hello.nixpkgs;
  testNestedComponents = pkgs.stdenv.mkDerivation {
    name = "test-nested-components";
    phases = [ "checkNestedPhase" ];
    nativeBuildInputs = tests.hello.matrix.all;
    checkNestedPhase = ''
      touch $out
      if [[ ! "''${nativeBuildInputs[*]}" =~ "hello-nested" ]]; then
        echo "ERROR: The \"all\" target in the \"hello\" project does \
      not contain the expected \"hello-nested\" component".
        exit 1
      fi
    '';
  };
in
(mappedTests // {
  all = builtins.attrValues mappedTests ++ [ testNestedComponents ];
})
