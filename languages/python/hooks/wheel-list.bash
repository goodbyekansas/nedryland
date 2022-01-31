#! /usr/bin/env bash

fixupOutputHooks+=('setWheelLink')

setWheelLink() {
  mkdir -p "${out:-}"/nedryland

  # first, get all wheels for this derivation
  wheels=("$wheel"/*.whl)
  if [ ! ${#wheels[@]} -eq 0 ]; then
    echo -n "${wheels[@]}" >"$out"/nedryland/wheels
  fi

  # then, get all wheels for dependencies
  # note that this file will contain all transitive dependencies
  # and is therefore naturally "recursive"
  for pi in ${propagatedBuildInputs:-}; do
    if [ -f "$pi"/nedryland/wheels ]; then
      echo -n " " >>"$out"/nedryland/wheels
      cat "$pi"/nedryland/wheels >>"$out"/nedryland/wheels
    fi
  done

  echo "" >>"$out"/nedryland/wheels
  shopt -u nullglob
}
