{ buildPlatform, gdb, lib, writeTextFile, makeSetupHook }:
makeSetupHook
{
  name = "${buildPlatform}-runner-hook";
  substitutions = {
    runner =
      writeTextFile {
        name = "runner.sh";
        executable = true;
        text = ''
          command=""
          if [ -n "$RUST_DEBUG" ]; then
            command="${gdb}/bin/gdb --args"
          fi
          command $command "$@"
        '';
      };
  };
}
  (builtins.toFile "${buildPlatform}-runner-hook" ''
    export CARGO_TARGET_${builtins.replaceStrings ["-"] ["_"] (lib.toUpper buildPlatform)}_RUNNER=@runner@
  '')
