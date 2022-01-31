#! /usr/bin/env bash
# Copy wheel to $out instead of installing it

wheelCopyPhase() {
    runHook preInstall

    mkdir -p "${out-}"
    cp dist/*.whl "$out"

    runHook postInstall
}

if [ -z "${installPhase-}" ]; then
    echo "Using wheelCopyPhase for install"
    installPhase=wheelCopyPhase
fi
