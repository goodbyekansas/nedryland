# Nedryland

![Checks](https://github.com/goodbyekansas/nedryland/workflows/Checks/badge.svg)
![Checks](https://github.com/goodbyekansas/nedryland/workflows/%F0%9F%93%96%20Deploy%20to%20Github%20Pages/badge.svg)

Nedryland is a collection of utilities and a build system for declaring, building and deploying
microservice solutions.

⚠ Note that Nedryland is currently under heavy development and is, although it is used in
production, not production-ready.

## Developer Setup

Install Nix by going to [nixos.org/nix/](https://nixos.org/nix/) and follow the
instructions.

Nedryland has support for extensions, one example is the [Nedryglot extension](https://github.com/goodbyekansas/nedryglot)
that provides tooling and opinionated defaults for multiple languages.

## Usage and Concepts

Documentation on how to use Nedryland and the design ideas behind it can be
found in the [manual](http://goodbyekansas.github.io/nedryland).

## Building the Manual

The manual is created with [mdBook](https://github.com/rust-lang/mdBook) which
is therefore needed to build the docs. Use `nix-shell -A docs` to get a shell
with mdbook, then cd to `docs`. You can use `mdbook serve` to get a web server
that will also watch and rebuild the book when changes are made. `mdbook build`
can be used to just build the book.

To build and open the book, call `nix-build -A docs` followed by
`xdg-open`/`open` `result/share/doc/nedryland/manual/index.html`.

# Contributing

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

We welcome contributions to this project! See the [contribution guide](CONTRIBUTING.md)
for more information.

# License

Licensed under
[BSD-3-Clause License](https://github.com/goodbyekansas/nedryland/blob/main/LICENSE).

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in the work by you, shall be licensed as above, without any additional terms or
conditions.
