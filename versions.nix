{
  rust = {
    stable = "1.52.1";
    analyzer = "2021-05-11";
  };

  # tonic version needs to be matched with
  # a tonic-build version
  tonic = "0.4.3";
  tonicFeatures = [ "tls" "tls-roots" ];
  tonicBuild = "0.4.2";

  wasilibc = {
    version = "20201210";
    rev = "5ccfab77b097a5d0184f91184952158aa5904c8d";
    sha256 = "1kxcy616vnqw4q2xkng9q67mgmq3gw2h4z6hkcwrqw1fjjp5qnbz";
  };
  wasmtime = {
    version = "0.22.1+40c4c6ac9";
    rev = "40c4c6ac9bde95c72666d0cafb2ede6c7045edf9";
    sha256 = "0p0a7167b2wg6x7xymvps604f94dr1gfm7kadnq333qchbjgn7sp";
  };

  terraform = "terraform_0_13";

  wasmer = {
    version = "0.17.0";
    sha256 = "05g4h0xkqd14wnmijiiwmhk6l909fjxr6a2zplrjfxk5bypdalpm";
    cargoSha256 = "1ssmgx9fjvkq7ycyzjanqmlm5b80akllq6qyv3mj0k5fvs659wcq";
  };
}
