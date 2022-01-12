_self: super: with super; {
  pocl = stdenv.mkDerivation {
    name = "pocl";
    version = "1.8.0";
    src = fetchFromGitHub {
      owner = "pocl";
      repo = "pocl";
      rev = "3f420ef735672e439097d020db605778dbc4a6a1";
      sha256 = "sha256-beO5pIpu0Lqeg+bZEzlu62Df7rAIUpthpjlzlUAAsQw=";
    };

    buildInputs = [
      hwloc
      llvm_11
      lttng-ust
      ocl-icd
      pkgconfig
      llvmPackages_11.clang
      llvmPackages_11.clang-unwrapped # for libclang headers
    ];

    nativeBuildInputs = [ cmake ];

    propagatedBuildInputs = [
      libgcc
    ];

    doCheck = false;

    cmakeFlags = [
      # the detection here was a bit strange
      "-DLLC_HOST_CPU=x86-64"

      # This is experimental, and we do not need it
      "-DENABLE_SPIR=OFF"

      # pocl's CMakeLists.txt expects xxxDIR variables to be relative
      # path, but the Cmake wrapper in nixpkgs sets it to absolute. Change it back
      "-DCMAKE_INSTALL_BINDIR=bin"
      "-DCMAKE_INSTALL_INCLUDEDIR=include"
      "-DCMAKE_INSTALL_LIBDIR=lib"
    ];

  };
}
