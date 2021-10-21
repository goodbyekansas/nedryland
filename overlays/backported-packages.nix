# Remove packages from this file when we update the nixpkgs version to include them
self: _super: {
  # Get a version 1.13 of fpm that doesn't break from nixpkgs-unstable (2021-10-21).
  # The version in nixpkgs 21.05 is 1.11 which has a bug. Since this is a tool and not a
  # library a minor version update should not break anyones requirements.
  fpm = import ./backported-fpm { inherit (self) lib bundlerApp bundlerUpdateScript; };
}
