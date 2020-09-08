self: super: {
  wasmer-with-run = self.rustPlatform.buildRustPackage rec {
    pname = "wasmer";
    version = "0.17.0";

    src = self.fetchFromGitHub {
      owner = "wasmerio";
      repo = pname;
      rev = version;
      sha256 = "05g4h0xkqd14wnmijiiwmhk6l909fjxr6a2zplrjfxk5bypdalpm";
      fetchSubmodules = true;
    };

    cargoSha256 = "1ssmgx9fjvkq7ycyzjanqmlm5b80akllq6qyv3mj0k5fvs659wcq";
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
