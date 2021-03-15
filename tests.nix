let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf/project.nix;
    hello = import ./examples/hello/project.nix;
    deployment = import ./deployment/project.nix;
  };

  mappedTests = builtins.mapAttrs (name: project: (project.override { enableChecks = true; }).matrix.all) tests;
in
(mappedTests // { all = builtins.attrValues mappedTests; })
