pkgs: docMatrix:
pkgs.runCommand "test-doc-out-path" { outPath = docMatrix.awesomeClient.docs.all; jason = pkgs.jq; } ''
  set -e
  touch $out
  assertPathExists() {
    if [ ! -d "$1" ]; then
      echo "$2"
      exit 101
    fi
  }

  assertEq() {
    if [ "$1" != "$2" ]; then
      echo "$3"
      exit 102
    fi
  }

  assertPathExists "$outPath/share/doc/manuel-gearbox/manuel" "Expected name and type override to work"
  assertPathExists "$outPath/share/doc/awesome-client/about" "Expected default name to be component name and default type to be set key"

  local sharks=$($jason/bin/jq -r .sharks "$outPath/share/doc/awesome-client/metadata.json")
  assertEq $sharks "5" "Expected doc set metadata to propagate to metadata.json (sharks should be 5)"
''
