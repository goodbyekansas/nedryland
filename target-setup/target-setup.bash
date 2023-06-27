setupTarget() (
  echo ""
  echo "👋 Hello! It looks like you are in a new @typeName@ component, lets do some setup!"
  # shellcheck disable=SC2050
  if [ "@templateDirDrv@" != "" ] && [ "@showTemplate@" == "1" ]; then
    echo "Files that should be here are:"
    @tree@ "@templateDirDrv@" -a --noreport --dirsfirst \
    | sed 's!@templateDirDrv@!'"$PWD"'!g' \
    | sed -E 's!@(\w+)@!${\1}!g' \
    | sed 's/ -> .*$*//g' \
    | @envsubst@
  fi
  echo ""
  echo -e "\e[1mDo you want to generate the missing files? [y/N]\e[0m"

  read -r -n 1 -s answer
  answer="${answer,,}"
  if [ "$answer" != "y" ]; then
    echo "💪 That's cool, good luck!"
    return 0
  fi

  @readVarStdin@

  for rel in $(cd "@templateDirDrv@" && find . -type f,l); do
    file="@templateDirDrv@/$rel"
    outname=$(echo "$rel" | sed -E 's!@(\w+)@!${\1}!g' | @envsubst@)
    if [ -f "$outname" ]; then
        echo "👌 $outname already exists"
    else
    mkdir -p "$(dirname "$outname")"
    substituteAll "$file" "$outname"
    echo "✔️ Generated $outname"
    fi
  done
  @initCommands@
)

checkTargetSetupMarkers() {
  if [ -n "${dontSetupTarget:-}" ]; then
    return
  fi

  @vars@

  markerFound=false

  # shellcheck disable=SC2043
  for marker in @markers@; do
    filename=$(echo "$marker" | sed -E 's!@(\w+)@!${\1}!g' | @envsubst@)
    if [ -e "$filename" ]; then
      markerFound=true
      break
    fi
  done

  if [ "$markerFound" = false ]; then
    setupTarget
  fi
}

shellHook="${shellHook:-}
checkTargetSetupMarkers
"
