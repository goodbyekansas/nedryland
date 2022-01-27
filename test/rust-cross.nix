lib: { assertMsg, baseRust, windowsRust, crossRust }:
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
{ }
