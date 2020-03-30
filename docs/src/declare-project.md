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
