#! /usr/bin/env bash

createCargoConfig() {
    if [ -f .cargo/config.toml ] && [ ! -L .cargo/config.toml ]; then
      echo -e "\e[31mERROR: $PWD/.cargo/config.toml exists and is not a link.\e[0m"
      echo "This is not currently supported and we need to link the file for"
      echo "internal dependencies to work. Please remove it and add to .gitignore."
      exit 1
    fi

    mkdir -p .cargo
    ln -sf @out@/cargo.config.toml .cargo/config.toml
    echo "🚜 Linked Cargo vendor config .cargo/config.toml -> @out@/cargo.config.toml"
}

preConfigureHooks+=(createCargoConfig)
preShellHooks+=(createCargoConfig)
