# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [10.0.0] - 2024-02-06

### Added
- Support for nixpkgs up to 23.11

### Changed
- The default linter is now statix instead of nix-lint. The name of the nix attribute and
  script is also changed from `nix-lint` to `nixlint` to be consistent with other linting
  tools.

### Fixed
- Shells were assuming that the `name` attribute always existed on derivations.
  This is not always true and `pname` can now also be used.

## [9.0.0] - 2023-11-07

### Changed
- shells are now created on the derivation directly instead of using pkgs.mkShell.

## [8.3.3] - 2023-09-26

### Fixed
- mdbook shell commands now finds the running process correctly, making the stop
  and open commands work.
- Error on github actions on macos, fixed by updating install-nix-action version.
- base.mkDerivation could not take pname + version instead of name, like stdenv.mkDerivation.

### Changed
- mkTargetSetup now creates a setupHook which adds itself to the shellHook of whatever
  it is added to. It respects the dontSetupTarget variable to not run.

## [8.3.2] - 2023-06-09

### Fixed
- checks.shellcheck can now handle files with spaces in the names.
- Shells for docs

## [8.3.1] - 2023-04-21

### Fixed
- override on mkComponent didn't override, just called the mkComponent with only
  the new arguments.
- When overriding shellCommands the help text was not updated.

## [8.3.0] - 2023-02-08

### Fixed

- collectComponentsRecursive uses nedrylandComponents if it exists, avoiding
  some evaluation of other attributes.

### Added

- Components can take `passthru`, they are exposed on the component like
  mkDerivation does, but not sent to the linkfarm. This can be useful to have
  expensive properties on the component accessible without adding a lot of eval cost.

### Changed
- Component linkFarms does not shadow any attributes, user added attributes takes precedence.

## [8.2.1] - 2023-01-27

### Fixed
- Add missing `-L` (log) to nix build in build-components workflow.

## [8.2.0] - 2023-01-27

### Fixed
- check to exit with the sum of all check's exit codes.

### Added
- build-components runs the cache filter in parallel and checks for all caches in the config.
- build-components option to run with remote store.

## [8.1.3] - 2023-01-17

### Added
- CI build-components: Support for arbitrary nix caches parsed from config.

### Fixed
- Deployment and docs special treatment is not given to component sets.
- Target linkfarms contains the full path to the target.

## [8.1.2] - 2023-01-17

### Fixed
- Collection error in the reusable workflow build-components.yml now correctly fails the
  sum-job at the end.
- Nested shells by normalizing the component hierarchy to only contain derivations or
  derivations that are also Nedryland components. Leaf nodes are always derivations and
  inner nodes are Nedryland components (which are also derivations).

## [8.1.1] - 2023-01-16

### Fixed
- Help message for entering a shell without a proper target.

## [8.1.0] - 2023-01-13

### Added
- Check for oldest supported Nixpkgs version. Can be overridden when importing Nedryland
  by passing `skipNixpkgsVersionCheck = true`.
- Support for passing `cachix-auth-token` to the setup action and matrix workflow.
- components are added directly onto ComponentsSets as well as under nedrylandComponents.

### Fixed
- Evaluation of base extensions for dependent project used the components derivation
  instead of the attrset.
- Target setup uses separate derivation for template directory. It otherwise depended on
  the source of the whole repo.
- Deployment wrongfully using `toString` on a path causing it to depend on the whole repo.
- Deployment linkFarm now looks like the other linkfarms.
- Priority of base extensions from dependent projects was higher than the current project,
  this is now reversed.

### Changed
- The checks apps has been moved into their own category "checks". And all-checks is renamed to all.

## [8.0.0] - 2023-01-11

### Added
- `documentation.mkMdbook` uses pre/post hooks for build and install and let users add inputs.
- `documentation.mkMdbook` run is now a shell function which creates an exit trap to shut down the server,
  also added open command to open the mdbook in a browser and a stop command to shut down the server.
- `documentation.mkMdbook` run uses ephemeral port, allowing multiple shells to serve mdbooks simultaneously.
- shells uses src if possible for "$componentDir" and fallbacks to nix file location.
- `base` is now available on the set returned from `mkProject`.
- Nix flake support.
- `nix develop` cd to correct location (assuming git project).
- lintPhase and lintInputs to be able to separate lints from other tests with `enableChecks`.
- `base.mkDerivation` will now detect `doChecks` correctly.
- `shellCommands.<command>.description` supports ANSI escape codes when printing the shell
  message.
- `actionlint` added to checks (former ci attribute).
- `check` script in the check attribute (`bin/check`) that runs all checks. All scripts uses
  $NEDRYLAND_CHECK_FILES for files to check or default to old/own way of discovering files.
- `inCI` on base, it just checks if the environment variable CI is set and is anything but
  an empty string.
- Github workflows `build-components` and `checks` for Nedryland projects on Github to use.

### Fixed
- When printing welcome text in shells, respect shellCommands' "show" attribute.
- Shells got all nativeBuildInputs elements twice.
- nix-lint in the ci output (`bin/nix-lint`) will no longer print help/version text once
  for each file.
- Shells not following the designated priority for `nativeBuildInputs`.

### Changed
- `mkTargetSetup` now requires a `typeName` describing the type of target it sets up.
- shellCommands adds `set -euo pipefail` before executing the script.
- All shells now have a command `shellHelp` which is also used to print the help on
  startup of the shell instead of the hard-coded nix string used previously.
- The "target" axis of the matrix is now exposed as `matrix.targets` instead of directly
  on the `matrix` attribute. This makes evaluation of components a lot faster.
- `targets.*` is now a link farm
- `all` is now a link farm 🚜
- `ci` has been renamed to `checks` and `ci` has become a derivation containing a github CI CLI.
- All components are now also derivations building a tree of symlink to the output of its'
  targets. The original component attributes are available in `<component>.componentAttrs`.

### Removed
- `base.languages`. This now lives in the [Nedryglot](https://github.com/goodbyekansas/nedryglot) extension.
- examples/protobuf. For the same reason.
- `base.mkExtension` and `base.mkComponentType`. Instead just return a set from the
  extension to be merged with base.
- Control of `nixpkgs`. Nedryland now has a mandatory argument for it so that users of
  Nedryland controls the version of nixpkgs.
- Ability to turn off/on checks on the matrix. They are always on. Instead, components
  that should not be checked can set `doCheck=false` in their derivations.

## [7.0.0] - 2022-11-24

### Added
- `documentation.mkSinglePage` now runs `preBuild`, `postBuild`, `preInstall` and `postInstall` hooks.
- `helpText` function to shell commands which can be used to print out the help in for
  example a `shellHook`.
- Re-export `prost` for Rust Protobuf generated code. This makes it easier to avoid
  version conflicts caused by the inter-dependency between prost and tonic.
- Python components exposes `pythonVersion`.
- All derivation shells gets default shellCommands.

### Fixed
- `mkDerivation` now uses the default shellCommands in `base.mkShellCommands` if none are supplied.
- Terraform components can define shellCommands.
- Generated setup.py files in python components excludes the generated tests folder.
- documentation derivations now merges `shellCommands` correctly.
- Python components' `nativeBuildInputs` and `checkInputs` now resolve lists properly
  again.

### Changed
- shellcheck from the ci attribute will now find more shell scripts and is faster.
- Changed order of shell dependencies so shellInputs can't change the behavior of checks in the shell.
- Python: Config settings for checks are generated outside of the component's working directory,
  which means setup.cfg.include is now just setup.cfg. Tools using the configs are wrapped to use the
  generated configs instead.
- shellCommands now check their syntax.

### Changed Versions
- nixpkgs from 21.11 to 22.05
- prost-build from 0.9.0 to 0.10.4 for protobuf
- tonic from 0.6.1 to 0.7.2

## [6.3.0] - 2022-09-19

### Fixed
- Python dependencies not being discovered when running pip install. Since dependencies
  are fetched with Nix, we instead tell pip to not "verify" them when doing the
  installation. This was a problem for example for PySide2 and Shiboken.

## [6.2.0] - 2022-07-11

### Added
- Sphinx documentation generation now supports Google-style docstrings thanks to the Napoleon extension shipped with Sphinx.
- Sphinx documentation can now pick up extra extensions from the config `[python] sphinx-extensions = [ "sphinx.ext.imgmath" ]`
- `shellCommands` can take sets with "script", "description", "args" and "show" to generate the shell welcome message for the command.

### Fixed
- shellCommands does not print any internal setup.
- Shells for `docs` derivations now works again, and the `doc` target itself warns that it is not a useful shell.

## [6.1.0] - 2022-06-16

### Fixed
- Python components can take `targetSetup` as a derivation (preferably made with `base.mkTargetSetup`) as well as a set of overrides.
- `shellCommands` for python components works like the others (can take a set with command_name = bash_code;).
- `shellCommands` input for rust components are merged with default.
- targetSetup expands variables in template files for the file tree preview.
- `shellCommands` can now run even if `NIX_BUILD_TOP` is unset (which it is when using nix-direnv).

### Added
- `targetSetup` can now use `@variableName@` in the `markerFiles` argument.
- `markerFiles` in `targetSetup` can now also be folders (or sockets or any other kind of file).
- Base extensions can now depend on `components` to get a set of all components.

## [6.0.0] - 2022-04-29

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
- Made target resolution lazy resulting in speedup since unnecessary targets stay unresolved.

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
