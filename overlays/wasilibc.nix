self: super:
let
  # set this to true to produce a wasilibc with debug symbols
  # TODO: there is probably a better place for this
  debug = true;
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
    version = "0.22.0";

    src = super.fetchFromGitHub {
      owner = "goodbyekansas";
      repo = pname;
      rev = "22ad43b43068f9944a042b2cfd6505f23d1b15b0";
      sha256 = "1sr9q5qwrqfhw6q7mlj5akzc9hm7vaw80khxl0irxng7d1by4dr0";
      fetchSubmodules = true;
    };
    cargoSha256 = "1s8ac1ab13bj1z10b629bck5n9m38wrrnj2l795cbs3xw70m6iid";

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
    name = "wasilibc-20201210";
    src = self.fetchFromGitHub {
      owner = "WebAssembly";
      repo = "wasi-libc";
      rev = "5ccfab77b097a5d0184f91184952158aa5904c8d";
      sha256 = "1kxcy616vnqw4q2xkng9q67mgmq3gw2h4z6hkcwrqw1fjjp5qnbz";
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
