#! /usr/bin/env bash

fixupOutputHooks+=('setWheelLink')

setWheelLink() {
  mkdir -p "${wheel:-}"/nedryland

  # first, get all wheels for this derivation
  wheels=("$wheel"/*.whl)
  if [ ! ${#wheels[@]} -eq 0 ]; then
    echo -n "${wheels[@]}" >"$wheel"/nedryland/wheels
  fi

  # then, get all wheels for dependencies
  # note that this file will contain all transitive dependencies
  # and is therefore naturally "recursive"
  for pi in ${propagatedBuildInputs:-}; do
    if [ -f "$pi"/nedryland/wheels ]; then
      echo -n " " >>"$wheel"/nedryland/wheels
      cat "$pi"/nedryland/wheels >>"$wheel"/nedryland/wheels
    fi
  done

  echo "" >>"$wheel"/nedryland/wheels
  shopt -u nullglob
}
