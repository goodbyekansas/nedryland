# Project

A project in Nedryland is a folder with a collection of [components](./component.md). They can be
components of only one type or of different types. A project is created by importing Nedryland in a
file and then exposing the [matrix](./matrix.md) in `default.nix` and shells in `shell.nix` so that it
works with the standard Nix tools.

To depend on Nedryland in a project, any standard
[Nix fetcher](https://nixos.org/nixpkgs/manual/#chap-pkgs-fetchers) can be used. More info on how
to set up a new project can be found in [Declaring The Project](../declare-project.md).
