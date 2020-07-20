{ pkgs }: {
  mkComponentType = { name, createFunction }: {
    "mk${pkgs.lib.toUpper (builtins.substring 0 1 name)}${builtins.substring 1 (builtins.stringLength name) name}" = createFunction;
  };

  mkExtension = { componentTypes ? { }, deployFunctions ? { }, languages ? { } }:
    componentTypes
    // {
      deployment = deployFunctions;
      inherit languages;
    };
}
