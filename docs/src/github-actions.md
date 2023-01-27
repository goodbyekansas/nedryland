# Github Actions

Nedryland contains actions and reusable workflows for Github Actions that can be reused in
projects to build and test the [matrix](./concepts/matrix.md).

# Build Components

This reusable workflow will build and test (through the `checkPhase`) all components that
correspond to the provided attribute (defaults to `default`). Usage looks like

```yml
# ...

jobs:
  build-matrix:
    name: Build all Component
    uses: goodbyekansas/nedryland/.github/workflows/build-components.yml@8.2.0
    secrets:
      nix-access-key: ${{ secrets.nix-access-key }}
    with:
      # The build platform (the one to run the build on.
      # x86_64-linux and x86_64-darwin are supported).
      build-platform: x86_64-linux

      # optional path to a nix config file to use.
      nix-config-path: ./.github/workflows/setup/nix.conf

      # optional Nix version to use.
      nix-version: 2.11.1

# ...
```

For a list of available options, see
[build-components.yml](https://github.com/goodbyekansas/nedryland/blob/8.2.0/.github/workflows/build-components.yml).

# Checks

This reusable workflow runs a set of linters and formatter for nix, shell
scripts and github actions. Each tool can be individually disabled. This action
assumes that the corresponding apps are forwarded from nedryland, in flake.nix
located in the repository root:

```nix
# flake.nix
{
  inputs.nedryland.url = github:goodbyekansas/nedryland;
  outputs = { nedryland }:
  {
    x86_64-linux.apps = nedryland.apps.x86_64-linux;
  }
}
```


```yml
jobs:
  lint:
    name: Lints
    uses: ./.github/workflows/checks.yml
    with:
      nix-version: 2.11.1
      actionlint: false
```
For a list of available options, see
[checks.yml](https://github.com/goodbyekansas/nedryland/blob/8.2.0/.github/workflows/checks.yml).

# Setup Nix

This action helps in setting up Nix for use together with Nedryland. It is used by "Build
Components", which exposes all of the options with a `nix-` prefix.

Usage looks like

```yml
# ...

jobs:
  build-thing:
    name: Build It
    steps:

    # ...

    - name: Setup Nix
      uses:  goodbyekansas/nedryland/setup-nix@8
      with:

        # SSH key for Nix to access private repos.
        access-key: ${{ secrets.nix-access-key }}

        # optional path to nix config.
        config-path: ./.github/workflows/nix.conf

        # optional Nix version to use.
        version: 2.11.1
        
    # ...

# ...
```

For a complete list of options, see
[action.yml](https://github.com/goodbyekansas/nedryland/blob/8.2.0/.github/actions/setup-nix/action.yml).
