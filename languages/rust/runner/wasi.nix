{ writeTextFile, wasmtime, makeSetupHook }:
makeSetupHook
{
  name = "wasi-runner-hook";
  substitutions = {
    runner =
      # run the tests through virtual vm, create a temp directory and map it to the vm
      writeTextFile {
        name = "runner.sh";
        executable = true;
        text = ''
          temp_dir=$(mktemp -d)
          ${wasmtime}/bin/wasmtime run --env=RUST_TEST_NOCAPTURE=1 --disable-cache --mapdir=::$temp_dir "$@"
          exit_code=$?
          rm -rf $temp_dir
          exit $exit_code
        '';
      };
  };
}
  (builtins.toFile "wasi-runner-hook" ''
    export CARGO_TARGET_WASM32_WASI_RUNNER=@runner@
  '')
