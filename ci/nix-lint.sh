#! /usr/bin/env bash

EXIT_CODE=0

while IFS= read -r -d $'' file; do
    if [ "$(basename "$file")" != "sources.nix" ] && [ "$(dirname "$file")" != "nix" ]; then
        @nixLinter@ "$file"
        EXIT_CODE=$((EXIT_CODE + $?))
    fi
done < <(find . -type f \! -path "./.git/*" -a -name '*.nix' -print0)

exit $EXIT_CODE
