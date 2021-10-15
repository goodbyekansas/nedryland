{ base, parents }:
base.languages.ewokese.mkChild {
  name = "Luke";
  parents = builtins.concatStringsSep ", " (builtins.map (p: "${p.name} version: ${p.version or "not-versioned"}") parents);
}
