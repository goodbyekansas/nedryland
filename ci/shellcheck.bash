#! /usr/bin/env nix-shell
#! nix-shell -i bash -p shellcheck
# shellcheck shell=bash

is_bash() {
    [[ $1 == *.sh ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0
    [[ $(file -b --mime-type "$1") == text/x-shellscript ]] && return 0
    return 1
}

EXIT_CODE=0

while IFS= read -r -d $'' file; do
    if is_bash "$file"; then
        shellcheck -W0 -s bash "$file"
        EXIT_CODE=$((EXIT_CODE + $?))
    fi
done < <(find . -type f \! -path "./.git/*" -print0)

exit $EXIT_CODE
