{ base }:
base.languages.rust.mkClient {
  name = "rusty-rust-windows";
  src = ./.;
  executableName = "rusty-rust";

  crossTargets = {
    includeNative = false;
    windows = { };
  };
}
