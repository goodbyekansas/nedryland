# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Rust packages no longer output duplicate dependencies 🍄.

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
