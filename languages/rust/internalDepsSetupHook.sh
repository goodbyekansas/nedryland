addRustDeps() {
  if [ -d "$1/src/rust" ]; then
    for dep in "$1/src/rust/"*; do
      export rustDependencies+=" $dep"
    done
  fi
}

addEnvHooks "$targetOffset" addRustDeps
