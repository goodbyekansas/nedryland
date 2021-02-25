# Nedryland

![Checks](https://github.com/goodbyekansas/nedryland/workflows/Checks/badge.svg)

Nedryland is a collection of utilities and a build system for declaring, building and deploying
microservice solutions.

## Developer Setup

Install Nix by going to [nixos.org/nix/](https://nixos.org/nix/) and follow the
instructions.

## Usage and Concepts

Documentation on how to use Nedryland and the desgin ideas behind it can be found in the book inside
the `docs/` folder.

## Building the Book

The book is created with [mdBook](https://github.com/rust-lang/mdBook) which is therefore needed to
build the docs. Navigate to the `docs/` folder and get a nix shell with mdBook in it (`nix-shell -p
mdbook`). You can use `mdbook serve` to get a web server that will also watch and rebuild the book
when changes are made. `mdbook build` can be used to just build the book.

To build and open the book, call `nix-build -A docs` followed by `xdg-open`/`open` `result/index.html`.
