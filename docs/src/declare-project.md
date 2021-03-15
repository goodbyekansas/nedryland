# Declaring the Project

## Machine Setup
You will need to install Nix on your computer. Visit [nixos.org/nix/](https://nixos.org/nix/) to do so.

The next thing you will need to create is a _project_. A _project_ consits of three files:
`project.nix`, `default.nix` and `shell.nix`. So, let's go ahead and set up a `project.nix`.

## Project Setup

First, you will need to import Nedryland. This can be done for example from a git repository and
might look something like

```nix
let nedryland = import (
  builtins.fetchGit {
    name = "nedryland";
    url = "git@github.com:goodbyekansas/nedryland.git";
    ref = "refs/tags/0.8.0";
  });
```

Then, we need to declare the project. To do that, we use the function `mkProject`.

```nix
project = nedryland.mkProject {
  name = "your-name";
  configFile = ./your-name.toml;
};
```

The function accepts a name for the project and a default config file to use for [project
configuration](#configuration). In the `project` set returned from the above call to `mkProject`,
there will be more utility functions that can be called to set up the project further.

## Creating the Matrix

To give you access to shells and build targets in the [matrix](./concepts/matrix.md), your call to `mkProject`
needs a list of `components`.

`components` will be your components as described and declared [here](./components.md). Passing them
to `mkProject` might look something like

```nix
project.mkMatrix {
  components = { callFile }: {
    example-component = callFile ./example-component/example-component.nix {};
  };

  # ...
}
```

`deployment` is described [here](./deployment.md) and is simply a set with your different deployment
targets, no magic there.

`extraShells` is any standard nix shells (as described
[here](https://nixos.org/nix/manual/#sec-nix-shell)) that you wish to have exposed by the matrix.

`lib` is a conventional key for any nix functions that you wish to expose to projects using your
project. These will simply be exposed on your project instance as `.lib`.

## Integrating with Nix

`project.nix` is not a standard Nix file and therefore will not be picked up by any Nix tools.
Nedryland relies 100% on standard Nix tools and therefore we also need to expose the matrix in a way
that Nix understands. The way this is done is through the files `default.nix` and `shell.nix`.
`default.nix` is what the command `nix-build` looks for when not provided with any filename
arguments. Therefore, we expose the build matrix in that file like this

```nix
# default.nix
(import ./project.nix).matrix
```

`shell.nix` is where `nix-shell` looks for shell definitions by default and therefore, we can use it
to expose the shells from the build matrix like this

```nix
# shell.nix
(import ./project.nix).shells
```

After this, you should be able to use `nix-build` and `nix-shell` to access targets as described
[here](./concepts/matrix.md). So, for example to build the target `package` of the `example-component`
declared above, you would invoke

```sh
$ nix-build -A example-component.package
```

and to get a shell for working on `example-component` you would invoke

```sh
$ nix-shell -A example-component
```

Note here that we only use the component name to invoke a shell. If there's only one target in the
component it will be used, otherwise the default is to use the `package` target. This default target
can be changed in the config file under `shells.defaultTarget`.

## Configuration

A project might need configuration for example for server addresses, deploy credentails or really
anything. Nedryland contains helpers for this that can be accessed by setting the `configFile`
argument to `mkProject`. This file is a TOML file that may or may not exist. If it exists, Nedryland
will parse it and make it available to components.

### Format

The config file is a [TOML](https://github.com/toml-lang/toml) file and the format of it is
controlled completely from the components as described below.

### Environment variable overrides

Environment variables can also be used to override parts of, or the whole configuration. To override
all the content of the config, use the environment var `PROJECT_NAME_config`, where `PROJECT_NAME`
is the name of your project.

To override specific settings, use the environment var `PROJECT_NAME_key_setting_name` where
`PROJECT_NAME` is once again the name of your project, `key` is the key used below in
`base.parseConfig` and `setting_name` is the name of the setting used in `structure` in the call to
`base.parseConfig`.

### Using Config in Components

When declaring a component, you can declare a dependency on some configuration from the config file
like this

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

The assignments set the default values in case the requested keys are not present in the
configuration. In this example, the corresponding TOML could look like

```toml
[my-component]
database = { url = "tcp://something", user = "user", password = "pass" }
```

Then, in your component declaration, you can use `config` any way you want.

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
repository. When importing another nedryland project, you can use the helper `importProject` in
Nedryland. This will give you access to the [matrix](./concepts/matrix.md) of that project and it can
also be sent in as `projectDependencies` when declaring your project in Nedryland. Doing so will
give you access to all base extensions from that project.

Example

```nix
# ...

otherProject = nedryland.importProject {
  name = "otherProject";
  url = "https://github.com/fabrikam/other-project.git";
  ref = "refs/tags/1.4.5";
};

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
