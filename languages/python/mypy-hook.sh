#! /usr/bin/env sh

addToMypyPath() {
    # We only want mypy dependencies that we've created ourselves to be in the path.
    if [ -f "$1/nedryland/add-to-mypy-path" ]; then
        addToSearchPathWithCustomDelimiter : MYPYPATH "$1"/@sitePackages@
    fi
}
addEnvHooks "${targetOffset:-}" addToMypyPath
