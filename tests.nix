let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf;
    hello = import ./examples/hello;
    deployment = import ./deployment;
  };

  mappedTests = builtins.mapAttrs (n: v: v.packageWithChecks) tests;
in
(mappedTests // { all = builtins.attrValues mappedTests; })
