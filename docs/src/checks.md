# Nedryland linters

Nedryland provides a set of linters/formatters, they are accessed in the
`checks` attribute, and as separate apps. The currently provided checks are:
- `nixfmt`: To format nix code. This tool has been customized to compare current
  code with correctly formatted code by default and take `--fix` to correct the
  code.
- `nix-lint`: To lint nix expressions for mistakes and code quality.
- `shellcheck`: To check shell scripts.
- `check`: To run all checks.

To forward linters from Nedryland to a project to something like this:
```nix
# flake.nix
{
  inputs = {
    nedryland.url = github:goodbyekansas/nedryland;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs =
    { nedryland
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    {
      apps = {
        checks = nedryland.apps.${system}.checks;
      };
    })
}
```
And then run it with `nix run .#checks`.

## Selecting Files
Sometimes a project contains files which should not be linted, for example 3rd party files
or generated scripts. To customize which files will be checked set
`$NEDRYLAND_CHECK_FILES` to point to a file containing a list (newline separated) of all
files to check.

## Extending the Set of Linters
`check` will run all scripts in its bin folder, which means that to extend the lint
toolset in a project, simply symlinkJoin it with a derivation containing more linters.
When writing a custom linter use `$NEDRYLAND_CHECK_FILES` to select files from
and fall back to some other way of discovering files. Use
`$NEDRYLAND_CHECK_COLOR` to check if colors should be in the output. The script
should be able to run without any arguments.
