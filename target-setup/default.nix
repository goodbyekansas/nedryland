pkgs: parseConfig:
{ name
, typeName
, markerFiles ? [ ]
, variableQueries ? { }
, templateDir ? null
, initCommands ? ""
, variables ? { }
, showTemplate ? true
}:
let
  attrsToLines = f: attrs: builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList f attrs);
  componentConfig = pkgs.lib.filterAttrs (_: v: v != null) (parseConfig {
    key = "components";
    structure = pkgs.lib.mapAttrs (_: _: null) (variableQueries // variables);
  });
in
pkgs.makeSetupHook
{
  name = "target-setup-${builtins.replaceStrings [ " " ] [ "-" ] name}";
  deps = [ pkgs.envsubst pkgs.tree ];
  substitutions = {
    inherit typeName showTemplate initCommands;
    envsubst = "${pkgs.envsubst}/bin/envsubst";
    tree = "${pkgs.tree}/bin/tree";
    vars = attrsToLines
      (k: v: "${k}=\"${v}\"\nexport ${k}")
      ((pkgs.lib.filterAttrs (_: v: v != null) variables) // componentConfig);
    readVarStdin = attrsToLines
      (varName: varQuery: ''
        echo "${varQuery}"
        read -r ${varName}
        export ${varName}
      '')
      (builtins.removeAttrs variableQueries (builtins.attrNames componentConfig));
    templateDirDrv =
      if templateDir != null then
        pkgs.runCommand
          "template-dir-${name}"
          { inherit templateDir; }
          "cp -rL $templateDir $out"
      else
        "";
    markers = builtins.concatStringsSep " " (builtins.map (s: "\"${s}\"") markerFiles);
  };
} ./target-setup.bash
