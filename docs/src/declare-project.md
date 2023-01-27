# Declaring the Project

## Machine Setup
You will need to install Nix on your computer. Visit
[nixos.org/nix/](https://nixos.org/nix/) to do so.

The next thing you will need to create is a _project_. A _project_ consits of
three files: `project.nix`, `default.nix` and `shell.nix`. So, let's go ahead
and set up a `project.nix`.

## Project Setup
There are two main ways of setting up a project, flakes and everything else.
Here we will cover flakes and fetchgit but any other method of fetching files
will of course also work.

### 1 Using flakes

We need two files, `flake.nix` and `project.nix`, 
[flakes](https://nixos.wiki/wiki/Flakes) are used to handle dependencies and set
up entry points and the project file declares the components, shells and other
attributes in the project.

```nix
# flake.nix
{
  description = "Project description.";

  inputs = {
    nedryland.url = github:goodbyekansas/nedryland;
    pkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { nedryland, pkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs' = pkgs.legacyPackages.${system};

      project = (import ./project.nix {
        pkgs = pkgs';
        nedryland = nedryland.lib.${system} { pkgs = pkgs'; };
      });
    in
    {
      packages = project.matrix // {
        # This make `$nix build` (without arguments)
        # result in a linkfarm of all components.
        default = project.all;
      };
      devShells = project.shells;
    });
}
```

```nix
# project.nix
{ nedryland, pkgs }:
(nedryland { inherit pkgs; }).mkProject {
  name = "project-name";

  components = { callFile }: {
    component1 = callFile ./path/to/component.nix { };
    # more components here
  };
}
```

After adding these files to the git index, nix flakes will recognize them. Then
to build `component1` just run `nix build .#component1`. To get a development
shell run `nix develop .#component1`. To build an inspectable file tree of the
project run just `nix build`.

### 2 With fetchGit

We will use three files, one for creating the project, one for building and one
for opening development shells.

First, you will need to import Nedryland. In this example we use fetchGit, and
since Nedryland needs a set of packages we also fetch nixpkgs and send it to
Nedryland. The we use `mkProject` to create a project with a component.

```nix
# project.nix
let
  pkgs = import (
    builtins.fetchGit {
      name = "nixpkgs";
      url = ;
    } { });

  nedryland = import (
    builtins.fetchGit {
      name = "nedryland";
      url = "git@github.com:goodbyekansas/nedryland.git";
      ref = "refs/tags/8.2.1";
    } { inherit pkgs; });
in
nedryland.mkProject {
  name = "project-name";

  components = { callFile }: {
    component1 = callFile ./path/to/component.nix { };
    # more components here
  };
}

```

To be able to build more ergonomically, we create a default.nix and expose the
project's matrix.

```nix
# default.nix
(import ./project.nix).matrix
```

Now `nix build -f default.nix component1` (or `nix-build -A component1` for the
old output) will build component1.

To add development shells we add the `shell.nix` file:

```nix
# shell.nix
(import ./project.nix).shells
```

Then `nix-shell -A component1` will launch a shell for working on component1.

## mkProject

mkProject is the main function to create a Nedryland project, the function
accepts a name for the project and a default config file to use for [project
configuration](#configuration), and some other inputs explained below. In the
`project` set returned from the above call to `mkProject`, there will be more
utility functions that can be called to set up the project further.

### Creating the Matrix

A project consists of [components](./components.md), and components have targets, which
are you build artifacts. To create components use the `components` argument in
`mkProject`. This argument (and all other arguments to `mkProject`) can be a function and
the function can request arguments from `base` (including base extension). An essential
argument to request is `callFile` which will call a component with a set of packages and
components. This function accepts either a nix file and a set of overrides. It works
similar to `callPackage` in nixpkgs. There is also `callFunction` which does the same but
without importing a path and instead directly calling a function.

```nix
mkProject {
  components = { callFile }: {
    example-component = callFile ./example-component/example-component.nix {};
  };

  # ...
}
```

`deployment` is described [here](./deployment.md) and is simply a set with your
different deployment targets, no magic there.

`extraShells` is any standard nix shells (as described
[here](https://nixos.org/nix/manual/#sec-nix-shell)) that you wish to have
exposed by the matrix.

`lib` is a conventional key for any nix functions that you wish to expose to
projects using your project. These will simply be exposed on your project
instance as `.lib`.

More details on the matrix can be found under [concepts](./concepts/matrix.md).

## Configuration

A project might need configuration for example for server addresses, deploy
credentails or really anything. Nedryland contains helpers for this that can be
accessed by setting the `configFile` argument to `mkProject`. This file is a
[TOML](https://github.com/toml-lang/toml) file that may or may not exist. If it
exists, Nedryland will parse it and make it available to components.

### Environment variable overrides

Environment variables can also be used to override parts of, or the whole
configuration. To override all the content of the config, use the environment
var `PROJECT_NAME_config`, where `PROJECT_NAME` is the name of your project.

To override specific settings, use the environment var
`PROJECT_NAME_key_setting_name` where `PROJECT_NAME` is once again the name of
your project, `key` is the key used below in `base.parseConfig` and
`setting_name` is the name of the setting used in `structure` in the call to
`base.parseConfig`.

### Using Config in Components

When declaring a component, you can declare a dependency on some configuration
from the config file like this

```nix
config = base.parseConfig {
  key = "my-component";
  structure = {
    database = {
      url = "";
      user = "";
      password = "";
    };
  };
};
```

The assignments set the default values in case the requested keys are not
present in the configuration. In this example, the corresponding TOML could look
like

```toml
[my-component]
database = { url = "tcp://something", user = "user", password = "pass" }
```

Then, in your component declaration, you can use `config` any way you want.

## Extensions

Nedryland can be extended by passing in extensions when creating the project.
This is done by passing a set in a list as the `baseExtenstions` argument to
`mkProject`.

This might look something like

```nix
# project.nix
nedryland.mkProject {
  name = "my-project";
  configFile = ./my-project.toml;
  baseExtensions = [
    ./nedryland-extensions/stuff.nix
  ];
}
```

and inside `./nedryland-extensions/stuff.nix` you declare the extension by
providing a set that will be merged with `base` from Nedryland.

```nix
# nedryland-extensions/stuff.nix
{ base, pkgs }: # all extensions are functions called with base and pkgs
{
  mkMyAwesomeComponentType1 = args: {
    # ...
  };

  mkMyAwesomeComponentType2 = args: {
    # ...
  };

  utilityFunction = arg1: arg2:
    true;

  # ...
}
```

Base will now contain these functions and can be called with for example
`base.utilityFunction`. Note that base is also an input to the extension
function, this is the base before the extension is applied. And since extensions
are applied in the order they are declared in `baseExtesions` in `mkProject`,
extensions can use functions defined in extensions earlier in the list.

### Using extensions from another repo

You can also configure Nedryland to use base extensions from other repositories
by importing that repository. This will give you access to the
[matrix](./concepts/matrix.md) of that project and it can also be sent in as
`projectDependencies` when declaring your project in Nedryland. Doing so will
give you access to all base extensions from that project.

Example

```nix
# ...

otherProject = import path/to/other/project/ { };

project = nedryland.mkProject {
  name = "my-project";
  configFile = ./my-project.toml;
  baseExtensions = [
    (import ./nedryland-extensions/my-extension.nix)
  ];
  projectDependencies = [ otherProject ];
};
```

This will give you access to all baseExtensions declared in `otherProject`.
