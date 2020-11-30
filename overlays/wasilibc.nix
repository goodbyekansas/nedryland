self: super:
{
  wasilibc = super.wasilibc.overrideAttrs (oldAttrs: {
    name = "wasilibc-20200602";
    src = self.fetchFromGitHub {
      owner = "WebAssembly";
      repo = "wasi-libc";
      rev = "5a7ba74c1959691d79580a1c3f4d94bca94bab8e";
      sha256 = "0s86rpn6pljw1s9lks91fp9k4l2l58cnd262v5mk6492p48y7kiv";
    };
  });
}
