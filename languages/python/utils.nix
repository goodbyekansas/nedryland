{
  resolveInputs = pythonPkgs: inputs:
    if builtins.isFunction inputs then
      (builtins.map
        (input: if input ? isNedrylandComponent then input.package else input)
        (inputs pythonPkgs))
    else (builtins.map (input: if input ? isNedrylandComponent then input.package else input) inputs);
}
