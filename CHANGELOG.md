# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Pre Terraform shell hook.
- Post Terraform shell hook.

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
