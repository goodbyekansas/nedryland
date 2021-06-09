let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf/project.nix;
    hello = import ./examples/hello/project.nix;
    deployment = import ./deployment/project.nix;
  };

  pkgs = tests.hello.nixpkgs;

  mappedTests = (builtins.mapAttrs
    (
      name: project: (
        project.override { enableChecks = true; }
      ).matrix.all
    )
    tests) // {
    combinedDeployment = import ./test/deployment.nix tests.hello.matrix.combinedDeployment.deploy pkgs.lib.assertMsg;
    nestedComponents = import ./test/nested-components.nix pkgs tests.hello;
  };
in
(mappedTests // {
  all = builtins.attrValues mappedTests;
})
