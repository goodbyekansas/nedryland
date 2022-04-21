{
  # https://rust-lang.github.io/rustup-components-history/
  rust = {
    stable = "1.60.0";
    analyzer = "2022-04-20";
  };

  # tonic version needs to be matched with
  # a tonic-build version
  tonic = "0.6.1";
  tonicFeatures = [ "tls" "tls-roots" ];
  tonicBuild = "0.6.0";

  wasilibc = {
    version = "20220420";
    rev = "7302f33f99233482de8eedfcd21495c20858e0e4";
    sha256 = "sha256-HzBT2ZNVEvYB+71fA6FgLV7JxDcRqxHoOePZGienPhc=";
  };

  wasmtime = {
    version = "0.36.0";
    rev = "c0e58a1e1c22b53e0330829057da6125da89bef1";
    sha256 = "sha256-nSA78eQRbJ5JTDquaRqRgFU0V8RVCzvWUONgHxGj+Mc=";
    cargoSha256 = "1y0vy0y3p5vca08cg1kbpk38yrhwrp0c555lawnfi2jpjjha5szz";
  };

  terraform = "terraform_0_13";
}
