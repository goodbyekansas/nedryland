toUpper: {
  mkComponentType = { name, createFunction }: {
    "mk${toUpper (builtins.substring 0 1 name)}${builtins.substring 1 (builtins.stringLength name) name}" = createFunction;
  };

  mkExtension = { componentTypes ? { }, deployFunctions ? { }, languages ? { } }:
    componentTypes
    // {
      deployment = deployFunctions;
      inherit languages;
    };
}
