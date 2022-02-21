base:
{
  resolveInputs = pythonPkgs: name: typeName: inputs:
    base.resolveInputs name typeName [ "package" ] (if builtins.isFunction inputs then
      (inputs pythonPkgs)
    else inputs);
}
