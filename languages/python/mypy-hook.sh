addToMypyPath() {
    # MYPY does not want python's own site-packages to be in the mypy path
    if [ $1 != @interpreterPath@ ]; then
        addToSearchPathWithCustomDelimiter : MYPYPATH $1/@sitePackages@
    fi
}
addEnvHooks "$targetOffset" addToMypyPath
