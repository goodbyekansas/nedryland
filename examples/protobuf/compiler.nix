{ base }:
base.callFile ../../languages/rust/protobuf/compiler {
  tonicBuildVersion = "=${base.versions.tonicBuild}";
}
