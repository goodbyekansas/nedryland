self: super:
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

  # convenience stdenv that uses clang 11 for wasi
  clang11Stdenv = (super.overrideCC super.stdenv super.buildPackages.llvmPackages_11.lldClang);

  # override wasilibc with a newer version that is compiled with clang 11
  wasilibc = (super.wasilibc.override {
    stdenv = (super.overrideCC super.stdenv super.buildPackages.llvmPackages_11.lldClangNoLibc);
  }).overrideAttrs (oldAttrs: {
    name = "wasilibc-20201202";
    src = self.fetchFromGitHub {
      owner = "goodbyekansas"; # TODO: change to upstream after https://github.com/WebAssembly/wasi-libc/pull/226 is in
      repo = "wasi-libc";
      rev = "b601c8509d3230b3abff3d12264b8c752ec3299c";
      sha256 = "0142kbdjdlj8d5hnmr65f5bpwfskfyfw7wv7g3f58cl4y4r367b8";
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
