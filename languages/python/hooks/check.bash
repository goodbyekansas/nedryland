#! /usr/bin/env bash

standardTests() {
    echo "Running pytest (with pylint, flake8, mypy, isort and black) 🧪"
    pytest --pylint --black --mypy --flake8 --isort --cov=. --cov-config=setup.cfg ./
}

# If there is a checkPhase declared, mk-python-component in nixpkgs will put it in
# installCheckPhase so we use that phase as well (since this is executed later).
if [ -n "${doStandardTests-}" ] && [ -z "${installCheckPhase-}" ]; then
    installCheckPhase=standardTests
fi
