# The Development Environment

Nedryland uses `nix-shell` (`default.nix`) or `nix develop` (flakes) to provide a
development environment for defined components. For this to work, `shell.nix` in the root
of the repository needs to expose the output of `project.mkShells`.

## Working on a component

To start a shell for working on a component called `hammond`, issue the command

```sh
$ nix-shell -A hammond
```

or if using flakes

```sh
$ nix develop .#hammond
```

This will download and expose all dependencies necessary to work on `hammond`, change the directory
to where `hammond` is defined and create a new shell session.

## Get a Shell with all Components

The special target `all` (`nix-shell -A all`/`nix develop .#all`) will drop you in a shell
session with access to all build outputs of the whole project. This can be useful to test
a set of components together.
