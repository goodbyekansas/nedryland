# Rust components

Nedryland provides some basic rust components.

## mkLibrary mkService mkClient mkComponent

- mkService and mkClient builds binaries.
- mkLibrary creates an unpacked rust package (unpacked .crate file) since rust builds everything from source.
- mkComponent is made for building extensions where you can create your own nedryland component types.

### Targets

Nedryland supports three different targets: windows, wasi and default. The default target is not set it will be your host platform.
If none of the default targets is what you need Nedryland provides a way for you to create custom targets too.

By default when creating a service, library or client you will get a default target. An example of this
could look like the following code.

```nix
{ base }:
base.languages.rust.mkLibrary {
  name = "best-library";
  src = ./.;
}
```

While this is nice for development it is not always desired such as when a library only works for a single platform.
You can solve it by using another one of the default platforms like in the following example.

```nix
{ base }:
base.languages.rust.mkLibrary {
  name = "example-library";
  src = ./.;
  defaultTarget = "windows";
}
```

You may also want to support multiple platforms. In that case you need to define the default target and also additional targets in the `crossTargets` attribute.

```nix
{ base }:
base.languages.rust.mkLibrary {
  name = "example-library";
  src = ./.;
  defaultTarget = "windows";

  crossTargets = {
    wasi = {};
  };
}
```

The targets for this component can be build in the following ways:
- `nix-build -A componentName` builds both for wasi and windows.
- `nix-build -A componentName.windows` builds windows.
- `nix-build -A componentName.wasi` builds wasi.
- `nix-build -A componentName.package` builds the package for the
  target platform. Since `defaultTarget` is set to `windows` the
  `package` attribute won't exist in this particular case.


You can share dependencies between platforms or have completely different dependencies too. Cross targets will not automatically get the
`buildInputs` from the default target. In this example the crossTarget takes the dependencies from the default target and combines it with
the platform specific dependencies that comes with it. In this case the `wasi` attribute inside `crossTargets` is a function which is handy
when you need to access attributes already provided for the target by nedryland. The target attribute (`wasi`) can also just be a set.


```nix
{ base, dependencyA , dependencyB }:
base.languages.rust.mkLibrary rec {
  name = "example-library";
  src = ./.;
  defaultTarget = "windows";

  # If dependencyA contains a windows target it will
  # automatically pick dependencyA.windows; if not
  # it will default to dependencyA.package.
  buildInputs = [ dependencyA dependencyB ];

  crossTargets = {
    # targetSpec is the supported cross target provided by nedryland.
    wasi = attrsForTargetSpec: {
      # Even if we re-use buildInputs for the windows target it
      # will pick depencencyA.wasi if it exists(not windows).
      # If not it will pick dependencyA.package.
      buildInputs = buildInputs ++ attrsForTargetSpec.buildInputs;
    };
  };
}
```

The attributes you specify in your crossTarget will override all the attributes of the package. This means
you can override any attribute. In the example below we just add build meta data to the version for wasi.

```nix
{ base, dependencyA , dependencyB }:
base.languages.rust.mkLibrary rec {
  name = "example-lib";
  version = "1.0.1";
  src = ./.;
  defaultTarget = "windows";
  buildInputs = [ dependencyA dependencyB ];

  crossTargets = {
    wasi = {
      version = "${version}+wasi" # Add "+wasi" as build meta data for the version.
      buildInputs = [ dependencyA ];
    };
  };
}
```

### mkCrossTarget

Nedryland exposes mkCrossTarget through base.languages.rust.mkCrossTarget. This function allows you to create your own custom cross target.

```nix
{ base, dependencyA , dependencyB }:
let
  riscVTarget = base.languages.rust.mkCrossTarget {
    stdenv = pkgs.pkgsCross.riscv32.clangStdenv;

    # Note that we only put required dependencies here for the platform.
    buildInputs = [ pkgs.pkgsCross.riscv32.systrayhelper ];
  };
in
base.languages.rust.mkLibrary rec {
  name = "example-lib";
  src = ./.;
  defaultTarget = riscVTarget;
  
  # Since we use the riscVTarget we will implicitly get the buildInputs for the target to (pkgs.pkgsCross.riscv32.systrayhelper).
  buildInputs = [ dependencyA dependencyB ];
}
```

