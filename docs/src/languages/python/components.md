# Python components

## Specifying dependencies

`shellInputs`, `checkInputs`, `buildInputs`, `nativeBuildInputs` and `propagatedBuildInputs` attributes can specified as either a list or a function.
In the case of a function the function will be called with the python package set of the version in the component.

### buildInputs
`buildInputs` for python components are dependencies are going to be built and linked. For runtime dependencies use `propagatedBuildInputs`.

### propagatedBuildInputs

Often when making python components you want to put your python dependencies into propagatedBuildInputs. This is because it maps to install_requires in `setup.py/setup.cfg`.
If you put `myOwnPythonPackageDependency` as a `buildInput` you would be able to test and run the library locally in the shell but if
another package depended on `example-lib` the other package would get errors because `myOwnPythonPackageDependency` would be missing.

```nix
{ pkgs, base, myOwnPythonPackageDependency }:

base.languages.python.mkLibrary rec{
  name = "example-lib";
  version = "1.0.0";
  src = ./.;
  pythonVersion = pkgs.python3;
  propagatedBuildInputs = [ myOwnPythonPackageDependency ];
  nativeBuildInputs = pythonPkgs: [ pythonPkgs.setuptools ];
}
```
