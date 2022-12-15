#! @bash@
# shellcheck shell=bash

set -uo pipefail
color="auto"
[ -n "${NEDRYLAND_CHECK_COLOR:-}" ] && color="always"

lintFiles() {
    exitCode=0
    # shellcheck disable=SC2086
    while mapfile -t -n 50 shellFiles && ((${#shellFiles[@]})); do
        if ! @shellcheck@ --color=$color "${shellFiles[@]}"; then
            exitCode=1;
        fi
    done <<< "$(@shfmt@ -f ${1:-.})"
    return $exitCode
}

if [ $# -eq 0 ]; then
    if [ -z "${NEDRYLAND_CHECK_FILES:-}" ]; then
        lintFiles
    else
        lintFiles "$(cat "$NEDRYLAND_CHECK_FILES")"
    fi
    exit $exitCode
else
    @shellcheck@ --color=$color "$@"
fi
