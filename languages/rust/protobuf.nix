{ name, protoSources, version, mkClient, includeServices, protobuf, stdenv, rustfmt, protoInputs }:
let
  protoIncludePaths = builtins.map (pi: pi.protobuf) protoInputs;
  rustInputs = builtins.map (pi: "${pi.rust.package.name}:${pi.rust.package.src}") protoInputs;
  tonicDependencyString = ''tonic = { version = "0.4", features = ["tls", "tls-roots"] }'';
in
stdenv.mkDerivation {
  inherit protoSources protoIncludePaths rustInputs;
  rustProtoCompiler = (import ./protobuf/compiler { inherit mkClient protobuf; }).package;
  name = "rust-${name}";

  PROTOC = "${protobuf}/bin/protoc";

  src = builtins.path { path = ./protobuf/src; inherit name; };

  # seem to need rustfmt, prob run on the resulting code
  nativeBuildInputs = [ rustfmt ];

  buildPhase = ''
        shopt -s extglob globstar nullglob
        includes=""
        for p in $protoIncludePaths; do
          includes+=" -I $p"
        done
        externs=""
        for extern in $rustInputs; do
          IFS=: read name path <<< "$extern"
          for f in $path/src/!(lib).rs; do
            f=''${f##*/}
            f=''${f%.rs}
            externs+="--extern .$f=\"::$name::$f\" "
          done
        done

        echo $rustProtoCompiler/bin/rust-protobuf-compiler \
          -I $protoSources \
          $includes \
          ${if includeServices then "--build-services" else ""} \
          $externs \
          -o ./src \
          $protoSources/**/*.proto

        $rustProtoCompiler/bin/rust-protobuf-compiler \
          -I $protoSources \
          $includes \
          ${if includeServices then "--build-services" else ""} \
          $externs \
          -o ./src \
          $protoSources/**/*.proto

        substituteInPlace ./Cargo.toml \
          --subst-var-by includeTonic ${if includeServices then "'${tonicDependencyString}'" else "''"} \
          --subst-var-by packageName ${name} \
          --subst-var-by version ${version} \
          --subst-var-by external "${builtins.foldl'
    (acc: cur: ''${acc}${cur.package.name} = { version = \"${cur.package.version}\", registry = \"nix\" }
          '') ""
    (builtins.map (pi: pi.rust) protoInputs)}"

        ${if includeServices then "echo 'pub use tonic;' >> ./src/lib.rs" else "" }
  '';

  installPhase = ''
    mkdir $out
    cp -r Cargo.toml src $out/
  '';
}
