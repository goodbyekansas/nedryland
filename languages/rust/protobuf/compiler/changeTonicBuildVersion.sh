changeTonicBuildVersion() {
    sed -i 's/tonic-build.*$/tonic-build = "@tonicBuildVersion@"/g' Cargo.toml
}

preConfigureHooks+=(changeTonicBuildVersion)
