#! @bash@
# shellcheck shell=bash

set -uo pipefail

if [ $# -eq 0 ]; then
    if [ -z "${NEDRYLAND_CHECK_FILES:-}" ]; then
        @nixLinter@ -r .
        exit $?
    else
        exitCode=0
        while mapfile -t -n 50 nix_files && ((${#nix_files[@]})); do
            if ! @nixLinter@ "${nix_files[@]}"; then
                exitCode=1;
            fi
        done <<< "$(grep ".nix$" < "$NEDRYLAND_CHECK_FILES")"
        exit $exitCode;
    fi
else
    @nixLinter@ "$@"
fi
