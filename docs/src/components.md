# Defining Components

To define components, there is a set of functions to use and the most flexible (but also lowest
level) is `base.mkComponent`. There is also a set of convenience functions to create different types
of components easier. Furthermore, there is also programming language specific versions of the
aforementioned functions.

So, let's declare a simple component. A component usually lives in a sub-folder in the repository so
create a folder `example-component` and create a file `example-component.nix` in it. In this file,
put the following content:

```nix
{ base }:

base.mkComponent {
  package = base.mkDerivation {
    name = "example-component";
    src = ./.;

    buildPhase = ''
      touch $out/hello-world
    '';
  };
}
```

This declares a component with a `package` target and uses Nedryland's `mkDerivation`
which is a wrapper around the standard `stdenv.mkDerivation`
[function](https://nixos.org/nixpkgs/manual/#sec-using-stdenv) but with an added filter
to exclude git-ignored files from the source before building.
.

## Exposing your Component

In order for your component to be used, it needs to be added to the build
[matrix](./concepts/matrix.md). This is done by adding it to the call to `mkProject` (usually inside
`project.nix`). A component is exposed by a call to `callFile` followed by optional
arguments. `callFile` is part of `base` and can therefore be accepted as an argument when declaring
components on a project.

So, something like this:

```nix
nedryland.mkProject {
  name = "my-project";

  components = { callFile } : {
    exampleComponent = callFile ./example-component/example-component.nix {};
  };

  # ...
}
```

The component will be exposed under the nix attribute `exampleComponent` so to build it you can use
`nix-build -A exampleComponent.<target>` where `target` is for example `package` (see
[matrix](../concepts/matrix.md))

## Component Dependencies
Nedryland supports components being dependent on other components. This is done by declaring
your dependency as an input. This is true for both for packages available in pkgs and your defined components.
Add your dependency to the argument list to your file and Nedryland will automatically send it to the function
call if available in either components or pkgs.

```nix
{ pkgs, base, myDependency }:

base.mkComponent {
  # ...
}
```

# Component Types

Nedryland contains a standard set of component types which are described below. Further component
types can be added in projects by extending _base_ like explained [here](../declare-project.md#extensions).

## Services
A service is a component that has no user interface and instead exposes some sort of a remote API.
Helpers exists to create gRPC services.

To define a service, your Nix file might look something like:

```nix
{ pkgs, base }:

base.mkService {
  name = "example-service";
  src = ./.;

  buildPhase = ''
    touch $out/hello-world
  '';
  };
}
```

## Clients
A client is a component that presents some sort of user interface. It can be either a GUI, a command
line interface or something else that a user interacts with (VR experience, etc.).

To define a client, your Nix file might look something like:

```nix
{ pkgs, base }:

base.mkClient {
  name = "example-client";
  src = ./.;

  buildPhase = ''
    touch $out/hello-world
  '';
  };
}
```

## Library
This component type is not exposed directly in base but rather by the different language helpers
(see below) and should be used to share common functionality in a library for the language in
question.

# Language Helpers
Nedryland also contains helpers for some programming languages that can be used when implementing
one of the supported (through what is included in Nedryland or through extensions) component types.
These helpers live under `base.languages`.

## Rust
Rust helpers live under `base.languages.rust` and will give you access to everything you
need for rust development out of the box:  rustc, cargo, rls, rust-analyzer, rust-src etc.
Components are usually named the same as their corresponding component types, i.e. there is a
`base.languages.rust.mkClient` to create a client in Rust.

## Python
Python helpers live under `base.languages.python` and will give you a full Python development
environment. Most of the helpers also accept an optional `pythonVersion` to select both between
minor and major (2/3) versions of Python.
