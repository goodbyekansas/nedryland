# Declaring the Project

## Machine Setup
You will need to install Nix on your computer. Visit [nixos.org/nix/](https://nixos.org/nix/) to do so.

The next thing you will need to create is a _project_. A project consits of three files:
`project.nix`, `default.nix` and `shell.nix`. So, let's go ahead and set up a `project.nix`.

## Project Setup

First, you will need to import Nedryland. This can be done for example from a git repository and
might look something like

```nix
let nedryland = import (
  builtins.fetchGit {
    name = "nedryland";
    url = "git@github.com:goodbyekansas/nedryland.git";
    ref = "refs/tags/0.1.0";
  });
```

Then, we need to declare the project. To do that, we use the function `mkProject`.

```nix
project = nedryland.mkProject {
  name = "your-name";
  configFile = ./your-name.toml;
};
```

The function accepts a name for the project and a default config file to use for project
configuration. In the `project` set returned from the above call to `mkProject`, there will be more
utility functions that can be called to set up the project further.

## Extensions

Nedryland can be extended by passing in extensions when creating the project. This is done by
passing a set created by calling `base.extend.mkExtension` in a list as the `baseExtenstions`
argument to `mkProject`.

This might look something like

```nix
project = nedryland.mkProject {
  name = "my-project";
  configFile = ./my-project.toml;
  baseExtensions = [
    (import ./nedryland-extensions/stuff.nix)
  ];
}
```

and inside `./nedryland-extensions/stuff.nix` you declare the extension using
`base.extend.mkExtension` like this

```nix
{ base, pkgs }: # all extensions are functions called with base and pkgs
base.extend.mkExtension {
  componentTypes = base.extend.mkComponentType {
    name = "myAwesomeComponentType1";
    createFunction = someFunction;
  } // base.extend.mkComponentType {
    name = "myAwesomeComponentType2";
    createFunction = someOtherFunction;
  };

  # ...
}
```

### Using the new Component Type

When adding a new component type, there is a bit of naming magic going on. The name sent in to
`mkComponentType` gets prefixed with `mk`. So to create a component of a type registered with

```nix
base.extend.mkComponentType {
  name = "compType";
  createFunction = someFunction;
}
```

you would use `base.mkCompType`.

### Using extensions from another repo

You can also configure Nedryland to use base extensions from other repositories by importing that
repository. When importing another repository, you will usually import its' `project.nix` which will
give you access to the [grid](./concepts/grid.md) of that project. The grid always exposes the
extensions that projects has in the key `baseExtensions`. Those can then be passed to Nedryland when
setting up your project.

Example

```nix
# ...

otherProject = import (
      builtins.fetchGit {
        name = "otherProject";
        url = "https://github.com/fabrikam/other-project.git";
        ref = "refs/tags/1.4.5";
      })/project.nix;

project = nedryland.mkProject {
  name = "my-project";
  configFile = ./my-project.toml;
  baseExtensions = [
    (import ./nedryland-extensions/my-extension.nix)
  ];
  projectDependencies = [ otherProject ];
};
```

This will give you access to all baseExtensions in `otherProject`.
