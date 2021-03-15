{ base, numpyWrapper, python3 }:
# extension arguments are intersected with components and pkgs
# so any input matching the name of a package will be auto populated
base.extend.mkExtension {
  languages = {
    python = {
      mkNumpyPython = attrs@{ name, version, src }:
        base.languages.python.mkClient {
          inherit name version src;
          pythonVersion = python3;
          propagatedBuildInputs = (pp: [ numpyWrapper.package ] ++ (attrs.propagatedBuildInputs or (x: [ ]) pp));
          shellHook = ''
            echo "This component was made through the extension!"
          '';
        };
    };
  };
}
