{ pkgs }:
let
  nedryland = import ./default.nix;
  # add any examples you want tested here
  tests = {
    hello = import ./examples/hello/project.nix {
      inherit pkgs nedryland;
    };
    documentation = import ./examples/documentation/project.nix {
      inherit pkgs nedryland;
    };
    dependencies = import ./examples/dependencies/child/project.nix {
      inherit pkgs nedryland;
    };
  };

  mappedTests = (builtins.mapAttrs
    (
      _: project: (
        project.override { enableChecks = true; }
      ).all
    )
    tests) // {
    combinedDeployment = builtins.trace "🎪 Running combined deployment test." import ./test/deployment.nix tests.hello.matrix.combinedDeployment.deploy pkgs.lib.assertMsg;
    sameWhenFiltered = builtins.trace "🎡 Running filter source tests." import ./test/filter-source.nix pkgs.lib.assertMsg tests.hello.matrix.sameThing1 tests.hello.matrix.sameThing2;
    docsTest = builtins.trace "🦖 Running docs tests." import ./test/docs.nix pkgs tests.documentation.matrix;
  };
in
(mappedTests // {
  all = builtins.attrValues mappedTests;
})
