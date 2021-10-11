pkgs: configContent: configRoot: prefix: { key, structure }:
let
  parsedConfig = builtins.fromTOML configContent;
  subConfig = pkgs.lib.mapAttrsRecursive
    (name: value:
      if
        (configRoot != null
          && builtins.isString value
          && builtins.substring 0 2 value == "./"
        ) then
        builtins.path
          {
            name = "nedryland-config-${builtins.concatStringsSep "-" name}";
            path = configRoot + "/${value}";
          } else value)
    (if builtins.hasAttr key parsedConfig then builtins.getAttr key parsedConfig else { });
in
with builtins;
pkgs.lib.mapAttrsRecursiveCond
  builtins.isAttrs
  (
    path:
    let
      envVarValue = getEnv "${prefix}_${key}_${builtins.concatStringsSep "_" path}";
    in
    value:
    if envVarValue != "" then envVarValue else (pkgs.lib.attrByPath path value subConfig)
  )
  structure
