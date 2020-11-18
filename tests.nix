let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf;
  };

  mappedTests = builtins.mapAttrs (n: v: v.packageWithChecks) tests;
in
(mappedTests // { all = builtins.attrValues mappedTests; })
