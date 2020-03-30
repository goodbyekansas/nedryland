# Defining Components

To define components, there is a set of functions to use and the most flexible (but also lowest
level) is `base.mkComponent`. There is also a set of convenience functions to create different types
of components easier. Furthermore, there is also programming language specific versions of the
aforementioned functions.

So, let's declare a simple component. A component usually lives in a sub-folder in the repository so
create a folder `example-component` and create a file `example-component.nix` in it. In this file,
put the following content:

```nix
{ pkgs, base }:

base.mkComponent {
  package = pkgs.stdenv.mkDerivation {
    name = "example-component";
    src = ./.;

    buildPhase = ''
      touch $out/hello-world
    '';
  };
}
```

This declares a component with a `package` target and uses the standard nix `mkDerivation`
[function](https://nixos.org/nixpkgs/manual/#sec-using-stdenv).

## Exposing your Component

In order for your component to be used, it needs to be added to the build
[grid](./concepts/grid.md). This is done by adding it to the call to `mkGrid` (usually inside
`project.nix`). A component is exposed by a call to `project.declareComponent` followed by optional
arguments.

So, something like this:

```nix
project.mkGrid {
  components = {
    example-component = project.declareComponent ./example-component/example-component.nix {};
  };

  # ...
}
```

## Component Dependencies
Nedryland supports components being dependent on other components. This is done by first declaring
your dependency as an input.

```nix
{ pkgs, base, myDependency }:

base.mkComponent {
  # ...
}
```

Then, in the project setup, make sure to declare your component with this dependency set.

```nix
example-component = project.declareComponent ./example-component/example-component.nix {
  dependencies = {
    myDependency = theOtherComponent;
  };
};
```

Nix will then ensure the correct build order and send in your dependency.

# Component Types

There is also a standard set of component types defined in Nedryland. The types are described below.

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

## Functions
A function is a well defined component that takes a set of inputs and produces a set of outputs.
Functions are defined together with a manifest describing things like their execution environment,
inputs, outputs, etc.

To define a function, this Nix snippet provides an example:

```nix
{ pkgs, base }:

base.mkFunction {
  name = "example-function";
  src = ./.;
  manifest = ./function.toml;

  buildPhase = ''
    touch $out/hello-world
  '';
  };
}
```

Note that the declaration of a function actually requires you to specify a manifest.
