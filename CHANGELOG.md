# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- languages now also aliases their name to package so we can do `nix-build -A rust` to build all rust packages.

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
