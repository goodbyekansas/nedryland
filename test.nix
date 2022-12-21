{ pkgs }:
let
  nedryland = import ./default.nix;
  # add any examples you want tested here
  examples = {
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
      _: project: project.all
    )
    examples) // {
    combinedDeployment = builtins.trace "🎪 Running combined deployment test." import ./test/deployment.nix examples.hello.matrix.combinedDeployment.deploy pkgs.lib.assertMsg;
    sameWhenFiltered = builtins.trace "🎡 Running filter source tests." import ./test/filter-source.nix pkgs.lib.assertMsg examples.hello.matrix.sameThing1 examples.hello.matrix.sameThing2;
    docsTest = builtins.trace "🦖 Running docs tests." import ./test/docs.nix pkgs examples.documentation.matrix;
    componentFnsTest = builtins.trace "📦 Running componentFns tests." import ./test/components.nix pkgs.lib.assertMsg;
  };
in
(mappedTests // {
  all = builtins.attrValues mappedTests;
})
