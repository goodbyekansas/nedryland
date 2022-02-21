rec {
  mkComponent = attrs:
    attrs // {
      overrideAttrs = f: attrs // (f attrs);
    };
  mkDerivation = mkComponent;

  mkService = mkComponent;
  mkClient = mkComponent;
  mkLibrary = mkComponent;
  resolveInputs = _: _: _: inputs:
    inputs;
}
