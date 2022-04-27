# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ci scripts forwards arguments
- `base.mkShellCommands` to create shell commands with a name and set of {command = script;}
- `shellCommands` to `base.mkDerivation`, partially applied `base.mkShellCommands` with
  name from the derivation
- if `shellCommands` exists when creating a shell, they are put in `nativeBuildInputs`
- Rust components can use path dependencies for nix dependencies, that patch section will automatically be removed when building outside the shell
- Rust runners can now use `debug` to run cargo commands with gdb (e.g. `debug cargo test`)
- Support for declaring inline extensions.

### Removed
- Removed themes

### Changed
- Rust wasm runner to be wasmtime instead of wasmer

### Changed Versions
- Nixpkgs updated to track the 21.11 release
- Rust 1.60
- wasilibc rev from 2022-04-21

### Fixed
- Target setup no longer triggering on python projects containing setup.cfg or pyproject.toml.
- Rust target not being exposed.

## [5.0.3] - 2022-03-25

### Fixed
- Pylint: Disabe R0801, since it's broken in current version
- Python: extendFile now writes out pylintrc files as .pylintrc

## [5.0.2] - 2022-03-25

### Fixed
- Error occurring when no default shell could be picked.
- Use default python version in clients and services.

### Changed
- Default pylintrc: increase threshold for duplicate-code check, 4->16.
- Default pylintrc: skip imports for duplicate-code check.

## [5.0.1] - 2022-02-22

### Fixed
- Shells works again

## [5.0.0] - 2022-02-22

### Fixed
- Target aliases on components now maintain that relationship when
  checks are enabled.

### Changed
- `base.enableChecks` is not a function that enables checks on a
  component and `base.checksEnabled` is now a flag that tells if
  checks are enabled on the matrix.

### Added
- base.resolveInputs to extract the correct targets from nedryland
  components when used as derivation inputs.
- timecode python library.

## [4.0.0] - 2022-02-14

### Added
- Documentation about documentation.
- `components` (as a set and not just separate) is sent into components.
- Add themes to base.
- Support for specifying python dependencies both as a function and a list.
- Nedryland components as python dependencies are resolved to package.
- Nedryland components as rust dependencies are resolved to the cross target platform we are currently building for or package.
- Generated documentation for protobuf.
- `wheel` as an output on python components' package and as a target on the component.
- `addWheelOutput` function to make a python derivation multi output with wheel.
- Python outputs test coverage.
- mkComponent for python.
- Some hooks in `base.languages.python.hooks` which could be useful.
- Python can now set a default python version in the project config.

### Removed
- mkPackage for python, it is now considered internal.

### Fixed
- Rust respects `includeNative = false;` when building docs.

### Changed
- Rust component to have a consistent way to specify targets to build.
- Rust & python component docs output folder from `./share/doc/api/NAME` to `./share/doc/NAME/api`.
- The docs on a component is now expected to be a set of derivations and metadata.
- All derivations in the docs set is symlinkjoined to one derivation.
- All other attributes are serialized into json at $out/share/doc/metadata.json.
- Docs derivations can declare a name and a type, by default the are chosen from the
  component name type is the key in the docs set.
- The structure of the output of docs is $out/share/doc/<component-name>.
- Rust gets all targets merged into one derivation with a front page of links to the
  different doc pages.
- Markdown is no longer a language, the functions are instead in `base.documentation`.
- Rust runners are now derivations with setup hooks instead of just attrsets. This makes
  them a bit more logical to author while the user experience stays the same.

## [3.3.0] - 2022-01-21
### Fixed
- Add support for rust cross target documentation.

### Added
- Support for not building the build platform for rust components.
  Add `includeNative = false` to the crossTargets to not build for the build platform.
- Pthreads as default build inputs for rust windows components.

### Changed
- Rust components had a rust attribute that contained the build platform target.
  Now it is a list containing all targets.

## [3.2.0] - 2022-01-14

### Added
- Overlay for pocl, a CPU-only OpenCL implementation (http://portablecl.org/).

## [3.1.0] - 2021-12-16

### Changed Versions
- Update Rust to version 1.57.0.

### Fixed
- Src filter for python now correctly excludes additional `srcExclude`s.
- The CI tools shellcheck and nix-lint will no longer check git ignored files.
- Deploy phases & variables can now use \ characters.
- Deploy phases can now use nix attributes as environment variables in bash consistently.

## [3.0.1] - 2021-11-25

### Fixed
- Src filter for `base.mkDerivation` now correctly excludes additional `srcExclude`s.

## [3.0.0] - 2021-11-24

### Added
- Python package keyrings-google-artifactregistry-auth which is
  "keyrings.google-artifactregistry-auth" on pypi.
- Python clients now also build wheels.
- Mypy ignore_missing_imports is now set globally.
- collectComponentsRecursive as a nedryland function.
- base.languages.markdown.mkSinglePage for generating html from a single markdown.

### Fixed

- Set isort profile to black to avoid conflicting linting between isort and black.
- Set flake8 configuration to ignore E203 whitespace before ':' to avoid conflicting
  linting between flake8 and black.
- Protobuf compiler shell working directory

### Removed

- Ability to download a Windows VM for running Rust code on. The usefulness of the feature
  did simply not warrant the complexity. Instead, you can set
  `NEDRYLAND_WINDOWS_HOST` to a machine where you have passwordless SSH access and
  cargo will use that machine for `run/test`.
- Single page documentation via mdBook or mkDocs, a separate component type will be added
  for that use case.

### Changed
- Python wheels will now be build to $out/nedryland instead of just $out.
- Generated API docs are now found under `api` instead of under `generated`
- Api docs are written to share/doc/api/name and general docs to share/doc/name.

### Updated Versions

- Rust: 1.56.1
- Rust Analyzer: 2021-11-17
- Tonic: 0.6.1
- Tonic build: 0.6.0

## [2.2.0] - 2021-11-01

### Added
- python components can now override configurePhase.
- python components can now override checkPhase which has higher priority than
  doStandardTests logic.

## [2.1.0] - 2021-10-25

### Added
- markdown-include python package

## [2.0.1] - 2021-10-22

### Fixed
- Various overlays that were depending on specific versions in nixpkgs 20.09.

## [2.0.0] - 2021-10-20

### Fixed
- Change sphinx and sphinx_rtd_theme to sphinx4 and sphinx4_rtd_theme respectively in
  order to make sure that we don't invalidate the build for anything that needs Sphinx.

### Changed
- "gitingore.nix" for src. This will make all of our own components ignore files that
  are inside gitignore in src.
- Project files importing Nedryland or `default.nix` need to be called as a set and not
  a function.
- Switched nixpkgs from the 20.09 branch to 21.05.

### Added
- `base.mkDerivation` which uses the new git ignore feature. It can take a stdenv and
  srcFilter input to customize what happens. srcFilter should be a function that takes 2
  inputs, `path: type: ` like [cleanSourceWith](https://github.com/NixOS/nixpkgs/blob/0e55920d5f79fbd336ac1a6e5f10e8ee16363d26/lib/sources.nix#L87)
- Add an optional argument as input in `default.nix` such that it is possible to
  explicitly define names of unfree packages that can be installed despite being unfree
  for a project when importing Nedryland. 
- Shellcheck is now available as part of the `ci` component.
- nix-lint is now available as part of the `ci` component.
- version argument to `mkProject`. It will be available on the project.

## [1.2.0] - 2021-08-31

### Added 
- Cross target for rust libraries, only needed to do development (nix-shell), the
  dependency should still be on the package and the platform of the dependant will build
  it for the correct target.

### Fixed
- Rust: Always set a target subdirectory when building, not only for cross compile. This way
  switching between targets will not trigger an unnecessary rebuild 🥝.

## [1.1.0] - 2021-08-05

### Added
- keepachangelog python package
- Use a version of github-release from newer nixpkgs

### Changed
- Strings starting with "./" in the config file are interpreted as paths relative to the
  config file.

### Fixed
- Rust components with cross compilation targets can generate docs.
- Nixfmt in the `ci` attribute will always use bash.
- Nixfmt in the `ci` attribute can now handle file names with spaces.

## [1.0.0] - 2021-07-03

### Added
- Markdown as a language and functions to turn markdown into html.
- `docs` as a target which can have requirements in the config file.
- Generated docs for rust and python that is merged with user written docs.
- Priority functions for determining deployment order in a combined deployment.
  Use `first` or `last` to set the deployment order of the component, or `priority` to set
  the priority explicitly.
- `targetsetup.nix` which python and rust now uses to setup new components. Variable names
  that exists in the project's config file under `components` are used instead of
  prompting user. Sending the set targetSetup to `mkPackage` in rust and python will
  combine attributes.  
- `versions.nix` which controls versions of some packages (rust, wasmer, wasmtime,
  ...). The set of versions is also accessible from `base`.
- `mkComponent` now accepts a `subComponents` set as an argument. The use of this is
  purely for convenience and will simply add the set of sub components to the component.
- Add `mkTheme` and theme as an argument to `mkProject`.
- Add shell alias for name of (rust) component that runs the component.
- Languages now also aliases their name to package so we can do `nix-build -A rust` to build all rust packages.
- `callFunction` method on base. Can be used in cases where you just want to evaluate an expression and don't have a file.
  You will need to specify the working directory manually since how else are we supposed to know where the shell is located
  when we just run a lambda.
- Shells for all targets, the default target for a component is `package` (can be changed in the project's config).
- `all` as a matrix target to build all targets on all components.

### Changed
- renamed `languages.python.mkUtility` and `languages.rust.mkUtility` to `mkLibrary`
- checks are now a separate evaluation of projects. i.e. call `override` on the result of `mkProject` with `{enableChecks = true;}`
- creating a component through `mkComponent` now require passing a name for it

### Removed
- `packageWithChecks` is no longer generated. See "Changed" for more details.

### Fixed
- Argument to combined deployment works the same as for regular deployment.
- shellInputs are now added to nativeBuildInputs instead of being an attribute on the
  derivation since that caused them to always be evaluated.
- Nested components are now included in the "all" matrix target.

## [0.8.1] - 2021-02-25

### Fixed
- Extend bases with dependencyProject's baseExtensions

## [0.8.0] - 2021-02-25

### Removed
- RUST_BACKTRACE was enabled by default. Removed it. Enable it manually when needed instead.
- sccache, was brittle and gave little benefit.
- Deploying from inside nix has been removed. Instead we create a deployment script which is called outside nix.

### Changed
- mkGrid does not exist anymore and instead a list of components is sent to mkProject and `matrix` is a 
  property on the project set, together with `shells`, `name`, `lib` etc. All attrs sent to `mkProject` also
  supports functions that takes a single set with members from `base`.
- Renamed `test` command to `check` due to bash if statement conflict (if statements actually run a function called test).
- Use niv for handling nix dependencies.
- Python overlays now work for both Python 3.7 and 3.8. Furthermore it is exposed both on the
  interpreter package and as <python-version>Packages.
- Set warnings as errors by default on all Rust projects. This can be turned off with the argument
  `warningsAsErrors` on all rust nix helpers (`mkService`, `mkClient` etc.).

### Added
- Make shells for nested components.
- mapComponentsRecursive available in base and nedryland.
- toUtility rust function that converts a rust package to a utility.
- `nixpkgs` as an attribute on nedryland to access the same version of packages nedryland uses.
- `mkDeployment` and `mkCombinedDeployment`.
- `mkClient` for python.
- Rust packages has proper cross-compilation support
- Support for checks when cross-compiling (set `doCrossCheck=true` to run `checkPhase` when
  cross-compiling.
- Examples of transitive protobuf modules.
- Language helper for generating protobuf modules.
- DeclareComponent supports returning attribute sets.
- Support for vendoring internal rust dependencies.
- Marker for Nedryland components, isNedrylandComponent = true.
- Automatically set MYPYPATH from propagatedBuildInputs in python packages.
- Support arbitrary attribute for python packages and make checkInputs, buildInputs, propagatedBuildInputs optional.
- Add overlays for python packages: cloudevents, functions-framework.
- Support arbitrary attribute for rust packages.
- Pre Terraform shell hook.
- Post Terraform shell hook.
- Terraform derivations accept nix store paths as source.
- Deploy target (`<component>.deploy`) that is a list of all attributes in the `deployment` of the
  component.

## [0.7.0] - 2020-08-27

### Added
- Expose Nedryland docs
- Add a state lock timeout to some TF ops

### Fixed
- Terraform plans are outputted in ascii
- Fixed missing rename in deployment.nix (terraformModule -> terraformComponent)

## [0.6.0] - 2020-08-24

### Changed
- Add mkTerraformComponent which is a provider-agnostic terraform module intended for deployment.
- Rust functions can now pass in shellInputs and shellHooks.
- Make src path invariant for Python and Rust packages. This makes it cacheable for everyone, irrespective of
  their path to the repositories. See
  [this](https://nix.dev/anti-patterns/language.html#reproducability-referencing-top-level-directory-with)
  for more details.
- Rust packages no longer output duplicate dependencies 🍄.
- Update rust-analyzer to 2020-08-03.

## [0.5.0] - 2020-07-29
### Added
- All python utilities now have wheels built as a separate derivation that then gets "linked" to the
  original derivation via a file in "$pkg/nedryland/wheels".

## [0.4.1] - 2020-07-23
### Fixed
- Only copy `setup.cfg` and `pylintrc` doesn't exist or it is a link for Python DCC functions.

## [0.4.0] - 2020-07-23
### Added
- Option to disable gbk tests for python packages.


## [0.3.1] - 2020-07-23
### Fixed
- Base extensions in dependant projects get combined base.


## [0.3.0] - 2020-07-23
### Added
- Added python language helper for utility libraries (base.languages.python.mkUtility).
