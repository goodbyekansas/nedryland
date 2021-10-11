versions: self: _: {
  wasmer-with-run = self.rustPlatform.buildRustPackage rec {
    pname = "wasmer";
    inherit (versions.wasmer) version cargoSha256;

    src = self.fetchFromGitHub {
      owner = "wasmerio";
      repo = pname;
      rev = version;
      inherit (versions.wasmer) sha256;
      fetchSubmodules = true;
    };

    cargoBuildFlags = [ "--features 'backend-cranelift'" ];
    nativeBuildInputs = with self; [ cmake pkg-config ];

    LIBCLANG_PATH = "${self.llvmPackages.libclang}/lib";

    meta = with self.lib; {
      description = "The Universal WebAssembly Runtime";
      longDescription = ''
        Wasmer is a standalone WebAssembly runtime for running WebAssembly outside
        of the browser, supporting WASI and Emscripten. Wasmer can be used
        standalone (via the CLI) and embedded in different languages, running in
        x86 and ARM devices.
      '';
      homepage = "https://wasmer.io/";
      license = licenses.mit;
      maintainers = with maintainers; [ filalex77 ];
    };
  };
}
