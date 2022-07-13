#! /usr/bin/env bash

EXIT_CODE=0

while IFS= read -r script; do
    @shellcheck@ "$script"
    EXIT_CODE=$((EXIT_CODE + $?))
done < <(@shfmt@ -f .)

exit $EXIT_CODE
