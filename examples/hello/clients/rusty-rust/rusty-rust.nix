{ base }:
base.languages.rust.mkClient {
  name = "rusty-rust";
  src = ./.;
}
