{ base }:
base.languages.rust.mkClient {
  name = "rusty-rust-cross";
  src = ./.;
  executableName = "rusty-rust";

  crossTargets = {
    windows = { };
  };
}
