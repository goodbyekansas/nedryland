{ lib, stdenv, baseRust, windowsRust, crossRust, callPackage }:
with lib;
# Build targets
assert assertMsg (baseRust ? package) "Expected baseRust to contain package.";
assert assertMsg (builtins.length baseRust.rust == 1) "Expected baseRust to only have one target in the `rust` attribute.";
assert assertMsg (!(baseRust ? windows)) "Expected baseRust to not contain windows since it must only contain build platform.";

assert assertMsg (windowsRust ? windows) "Expected windowsRust to contain a windows target (windows attribute).";
assert assertMsg (builtins.length windowsRust.rust == 1) "Expected windowsRust to only have one target in the `rust` attribute since build platform is ignored.";
assert assertMsg (!(windowsRust ? package)) "Expected windowsRust to not contain package since it must only contain the windows target.";

assert assertMsg (crossRust ? windows) "Expected crossRust to contain a windows target.";
assert assertMsg (crossRust ? package) "Expected crossRust to contain package.";
assert assertMsg (builtins.length crossRust.rust == 2) "Expected crossRust to have two targets in the `rust` attribute since it must build both for build platform and for windows.";

# Docs
# Have to change these tests later when we combine all docs to a single target.
assert assertMsg (baseRust ? docs.api) "Expected baseRust to contain api docs in `docs.api`";
assert assertMsg (lib.isDerivation baseRust.docs) "Expected baseRust.docs to be a derivation";
assert assertMsg (lib.isDerivation baseRust.docs.api) "Expected baseRust.docs.api to be a derivation";

assert assertMsg (windowsRust ? docs.api) "Expected windowsRust to contain api docs in `docs.api`";
assert assertMsg (lib.isDerivation windowsRust.docs) "Expected windowsRust.docs to be a derivation";
assert assertMsg (lib.isDerivation windowsRust.docs.api) "Expected windowsRust.docs.api to be a derivation";

assert assertMsg (crossRust ? docs.api) "Expected crossRust to contain docs.";
assert assertMsg (lib.isDerivation crossRust.docs) "Expected crossRust.docs to be a derivation";
assert assertMsg (lib.isDerivation crossRust.docs.api) "Expected crossRust.docs.api to be a derivation";

# buildInput propagation tests
let
  base = import ./mock-base.nix;
  versions = import ../versions.nix;
  rust = callPackage ../languages/rust { inherit base versions; };

  normalComponent = rust.mkClient {
    name = "normal";
    src = ./.;
    buildInputs = [ "depA" "depB" ];
  };

  differentDefault = rust.mkClient {
    name = "riskfree-v";
    src = ./.;
    defaultTarget = "windows";
    buildInputs = [ "pthreads-of-win" "ms-roy" ];
  };

  crossTargets = rust.mkClient {
    name = "criss-cross";
    src = ./.;

    defaultTarget = rust.mkCrossTarget {
      inherit stdenv;
      output = "orange";
    };
    buildInputs = [ "🍊" ];

    crossTargets = {
      "stop-station-5" = rust.mkCrossTarget {
        name = "paus-station-5";
        inherit stdenv;
        buildInputs = [ "🍏" ];
      };
    };
  };

  knownAndCross = rust.mkClient {
    name = "known";
    src = ./.;
    buildInputs = [ "🦧" ];

    crossTargets = {
      wasi = { };
      windows = {
        name = "fönster";
      };
    };
  };

  targetSpecWithInputs = rust.mkClient {
    name = "criss-cross";
    src = ./.;

    defaultTarget = rust.mkCrossTarget {
      inherit stdenv;
      output = "orange";
      buildInputs = [ "🍏" ];
    };
    buildInputs = [ "🍊" ];

  };
in
assert assertMsg ([ "depA" "depB" ] == normalComponent.package.buildInputs) "Expected to get buildInputs when specifying buildInputs";
assert
assertMsg
  (
    (builtins.elem "pthreads-of-win" differentDefault.windows.buildInputs) &&
    (builtins.elem "ms-roy" differentDefault.windows.buildInputs) &&
    # Currently we automatically add a dependency for all windows targets.
    (builtins.length differentDefault.windows.buildInputs == 3)
  )
  "Got unexpected buildInputs when creating client for Windows.";
assert
assertMsg
  (
    (crossTargets.orange.buildInputs == [ "🍊" ]) &&
    (crossTargets.stop-station-5.buildInputs == [ "🍏" ])
  )
  "Expected apples to be apples and oranges to be oranges";
assert
assertMsg
  (knownAndCross.package.buildInputs == [ "🦧" ])
  "Expected package to have single buildInput";
assert
assertMsg
  (knownAndCross.wasi.buildInputs == [ ])
  "Expected wasi to have zero buildInputs";
assert
assertMsg
  (knownAndCross.windows.name == "fönster")
  "Expected windows to be renamed to fönster but was ${knownAndCross.windows.name}";
assert
assertMsg
  (crossTargets.stop-station-5.name == "paus-station-5")
  "Expected stop-station-5 to be renamed to paus-station-5 but was ${crossTargets.stop-station-5.name}";
assert
assertMsg
  (targetSpecWithInputs.orange.buildInputs == [ "🍏" ])
  "Expected overriden buildInputs in target spec to override outer scope (oranges becomes apples)";
{ }
