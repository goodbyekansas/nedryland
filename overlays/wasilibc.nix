self: super:
{
  wasilibc = super.wasilibc.overrideAttrs (oldAttrs: {
    name = "wasilibc-20201202";
    src = self.fetchFromGitHub {
      owner = "WebAssembly";
      repo = "wasi-libc";
      rev = "378fd4b21aab6d390f3a1c1817d53c422ad00a62";
      sha256 = "0h5g0q5j9cni7jab0b6bzkw5xm1b1am0dws2skq3cc9c9rnbn1ga";
    };
  });
}
