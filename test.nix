let
  # add any examples you want tested here
  tests = {
    protobuf = import ./examples/protobuf/project.nix;
    hello = import ./examples/hello/project.nix;
    deployment = import ./deployment/project.nix;
    documentation = import ./examples/documentation/project.nix;
    dependencies = import ./examples/dependencies/child/project.nix;
  };

  pkgs = tests.hello.nixpkgs;

  mappedTests = (builtins.mapAttrs
    (
      _: project: (
        project.override { enableChecks = true; }
      ).matrix.all
    )
    tests) // {
    combinedDeployment = import ./test/deployment.nix tests.hello.matrix.combinedDeployment.deploy pkgs.lib.assertMsg;
    nestedComponents = import ./test/nested-components.nix pkgs tests.hello;
    sameWhenFiltered = import ./test/filter-source.nix pkgs.lib.assertMsg tests.hello.matrix.sameThing1 tests.hello.matrix.sameThing2;
    versionTest = import ./test/dependencies.nix tests.dependencies.matrix.nooo pkgs.lib.assertMsg;
    rustCross = import ./test/rust-cross.nix {
      inherit (pkgs) lib callPackage stdenv;
      inherit (tests.hello.matrix) baseRust windowsRust crossRust;
    };
    docsTest = import ./test/docs.nix pkgs tests.documentation.matrix;
    pythonWheel = import ./test/python-wheel.nix pkgs.lib.assertMsg tests.hello.matrix.pythonHello;
  };
in
(mappedTests // {
  all = builtins.attrValues mappedTests;
})
