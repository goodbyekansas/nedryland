pkgs: docMatrix:
if pkgs.lib.versionAtLeast pkgs.lib.version "22.11" || pkgs.system != "x86_64-darwin" then
  pkgs.runCommand "test-doc-out-path" { outPath = docMatrix.awesomeClient.docs; jason = pkgs.jq; } ''
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

    assertPathExists "$outPath/share/doc/client-docs/manuel" "Expected name and type override to work"
    assertPathExists "$outPath/share/doc/awesome-client/about" "Expected default name to be component name and default type to be set key"

    local sharks=$($jason/bin/jq -r .sharks "$outPath/share/doc/awesome-client/metadata.json")
    assertEq $sharks "5" "Expected doc set metadata to propagate to metadata.json (sharks should be 5)"
  ''
else
  builtins.trace "The watchdog Python package (used by mkdocs) is broken in nixpkgs < 22.11 on macOS(x86), skipping test" { }
