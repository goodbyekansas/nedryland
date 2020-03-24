pkgs: configContent: prefix: { key, structure }:
let
  parsedConfig = builtins.fromTOML configContent;
  subConfig = (if builtins.hasAttr key parsedConfig then builtins.getAttr key parsedConfig else {});
in
  with builtins;
  pkgs.lib.mapAttrsRecursiveCond
    (a: isAttrs a)
    (
      path: value:
        let
          envVarValue = getEnv "${prefix}_${key}_${concatStringsSep "_" path}";
        in
          if envVarValue != "" then envVarValue else (pkgs.lib.attrByPath path value subConfig)
    )
    structure
