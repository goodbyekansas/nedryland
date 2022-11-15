#! /usr/bin/env bash

standardTests() {
    echo "Running pytest (with pylint, flake8, mypy, isort, coverage and black) 🧪"
    pytest \
      --pylint --pylint-rcfile "$(pylint --print-generated-config-path)" \
      --black \
      --mypy --mypy-config-file "$(mypy --print-generated-config-path)" \
      --flake8 --flake8-config "$(flake8 --print-generated-config-path)" \
      --isort --isort-config "$(isort --print-generated-config-path)" \
      --cov=. --cov-config "$(coverage --print-generated-config-path)" ./
}

# If there is a checkPhase declared, mk-python-component in nixpkgs will put it in
# installCheckPhase so we use that phase as well (since this is executed later).
if [ -n "${doStandardTests-}" ] && [ -z "${installCheckPhase-}" ]; then
    installCheckPhase=standardTests
fi
