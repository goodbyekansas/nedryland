versions: self: super:
let
  # set this to true to produce a wasilibc with debug symbols
  # TODO: there is probably a better place for this
  debug = false;
in
{
  # create statically built versions of the llvm libraries (wasi does not support dynamic linking)
  llvmPackages_11 = super.llvmPackages_11 // {
    libraries = super.llvmPackages_11.libraries // rec {
      libcxxabi = super.llvmPackages_11.libraries.libcxxabi.override {
        enableShared = false;
      };
      libcxx = super.llvmPackages_11.libraries.libcxx.override {
        enableShared = false;
        inherit libcxxabi;
      };
    };
  };

  # This is for a bug in readdir in wasmtime, when the fix is in switch back to main
  # https://github.com/bytecodealliance/wasmtime/pull/2494
  wasmtime = super.rustPlatform.buildRustPackage rec {
    pname = "wasmtime";
    version = versions.wasmtime.version;

    src = super.fetchFromGitHub {
      owner = "bytecodealliance";
      repo = pname;
      inherit (versions.wasmtime) rev sha256;
      fetchSubmodules = true;
    };
    cargoSha256 = "1kkh7ssq557sg83vxnf6khw6lm74j83nkhkmyz4fnb78xr26ls5i";

    nativeBuildInputs = [ super.python super.cmake super.clang ] ++
      super.lib.optionals super.stdenv.isDarwin [ super.xcbuild ];
    buildInputs = [ super.llvmPackages.libclang ] ++
      super.lib.optionals super.stdenv.isDarwin [ super.darwin.apple_sdk.frameworks.Security ];
    LIBCLANG_PATH = "${super.llvmPackages.libclang}/lib";

    doCheck = false;

    meta = with super.lib; {
      description = "Standalone JIT-style runtime for WebAssembly, using Cranelift";
      homepage = "https://github.com/CraneStation/wasmtime";
      license = licenses.asl20;
      maintainers = [ maintainers.matthewbauer ];
      platforms = platforms.unix;
    };
  };

  # convenience stdenv that uses clang 11 for wasi
  clang11Stdenv = (super.overrideCC super.stdenv super.buildPackages.llvmPackages_11.lldClang);

  # override wasilibc with a newer version that is compiled with clang 11
  wasilibc = (super.wasilibc.override {
    stdenv = (super.overrideCC super.stdenv super.buildPackages.llvmPackages_11.lldClangNoLibc);
  }).overrideAttrs (oldAttrs: {
    name = "wasilibc";
    version = versions.wasilibc.version;
    src = self.fetchFromGitHub {
      owner = "WebAssembly";
      repo = "wasi-libc";
      inherit (versions.wasilibc) rev sha256;
    };

    # we need to add two -isystem flags due to nix purity. The clang in Nix does not add any
    # standard include paths (i.e. $sysroot/include) is not added as an include path. This used to
    # be the case for clang 8 but not anymore for 9+
  } // (if debug then {
    # we need to remove the check that defines will match up
    # since they won't for debug
    patches = [
      ./remove-define-check.patch
    ];

    # do not do _any_ stripping
    dontStrip = true;
    dontStripTarget = true;
    dontStripHost = true;

    makeFlagsArray = oldAttrs.makeFlagsArray or [ ] ++ [
      "WASM_CFLAGS=-g -isystem ../sysroot/include -isystem sysroot/include"
    ];
  } else {
    makeFlagsArray = oldAttrs.makeFlagsArray or [ ] ++ [
      "WASM_CFLAGS=-O2 -DNDEBUG -isystem ../sysroot/include -isystem sysroot/include"
    ];
  }));
}
