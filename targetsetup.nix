pkgs: parseConfig:
{ name
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
  templateDir' = if templateDir != null then (builtins.toString templateDir) else "";
in
pkgs.writeTextFile {
  name = "target-setup-${builtins.replaceStrings [ " " ] [ "-" ] name}";
  executable = true;
  destination = "/bin/target-setup";
  text =
    ''
      source $stdenv/setup > /dev/null 
      componentSetup() {
        echo ""
        echo "👋 Hello! It looks like you are in a new ${name} component, lets do some setup!"
        if [ "${templateDir'}" != "" ] && [ "${builtins.toString showTemplate}" == "1" ]; then
          echo "Files that should be here are:"
          ${pkgs.tree}/bin/tree "${templateDir'}" -a --noreport --dirsfirst \
          | sed 's!${templateDir'}!'"$PWD"'!g' \
          | sed -E 's!@(\w+)@!''${\1}!g' \
          | sed 's/ -> .*$*//g' \
          | ${pkgs.envsubst}/bin/envsubst
        fi
        echo ""
        echo -e "\e[1mDo you want to generate the missing files? [y/n]\e[0m"

        read -n 1 -s answer

        if [ "$answer" != "y" ]; then
          echo "💪 That's cool, good luck!"
          return 0
        fi

        ${vars}
        ${readVarStdin}

        for rel in $(find ${templateDir'} -type f,l | sed 's|${templateDir'}/||g'); do
          #rel=$(realpath --relative-to="${templateDir'}" "$file")
          file=${templateDir'}/$rel
          outname=$(echo $rel | sed -E 's!@(\w+)@!''${\1}!g' | ${pkgs.envsubst}/bin/envsubst)
          if [ -f $outname ]; then
              echo "👌 $outname already exists"
          else
            mkdir -p $(dirname $outname)
            substituteAll "$file" "$outname"
            echo "✔️ Generated $outname"
          fi
        done
        ${initCommands}
      }
      markers=(${builtins.concatStringsSep " " markerFiles})
      markerFound=false
      for marker in ''${markers[@]};do
        if [ -f "$marker" ]; then
          markerFound=true
          break
        fi
      done

      if [ "$markerFound" = false ]; then
        (componentSetup) #Using a subshell to not shadow or leak variables back here
      fi
    '';
}
