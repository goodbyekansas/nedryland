{
  rust = {
    stable = "1.53.0";
    analyzer = "2021-06-29";
  };

  # tonic version needs to be matched with
  # a tonic-build version
  tonic = "0.4.3";
  tonicFeatures = [ "tls" "tls-roots" ];
  tonicBuild = "0.4.2";

  wasilibc = {
    version = "20210526";
    rev = "3c4a3f94d1ce685a672ec9a642f1ae42dae16eb1";
    sha256 = "0amxbr7g94053g4brdl6nr05b5l36bf5yq9s2l5sya17sf2lajps";
  };

  wasmtime = {
    version = "0.22.1+40c4c6ac9";
    rev = "40c4c6ac9bde95c72666d0cafb2ede6c7045edf9";
    sha256 = "0p0a7167b2wg6x7xymvps604f94dr1gfm7kadnq333qchbjgn7sp";
    cargoSha256 = "0qx146wdf2m3wsaabclcrqjp184j2jq8lp3sk1rg3jr5jwh9w4nn";
  };

  terraform = "terraform_0_13";
}
