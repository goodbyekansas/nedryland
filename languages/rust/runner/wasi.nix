{ hostPlatform, writeTextFile, attrs, ... }:
if hostPlatform == "wasm32-wasi" then {
  # run the tests through virtual vm, create a temp directory and map it to the vm
  CARGO_TARGET_WASM32_WASI_RUNNER = (
    attrs.CARGO_TARGET_WASM32_WASI_RUNNER or (writeTextFile {
      name = "runner.sh";
      executable = true;
      text = ''
        temp_dir=$(mktemp -d)
        wasmer run --env=RUST_TEST_NOCAPTURE=1 --mapdir=:$temp_dir "$@"
        exit_code=$?
        rm -rf $temp_dir
        exit $exit_code
      '';
    })
  );
} else { }
