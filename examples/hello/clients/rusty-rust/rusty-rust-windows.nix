{ base }:
base.languages.rust.mkClient {
  name = "rusty-rust-windows";
  src = ./.;
  executableName = "rusty-rust";
  defaultTarget = "windows";
}
