{ base
, name
, protoSources
, version
, includeServices
, protobuf
, rustfmt
, protoInputs
, tonicVersion
, tonicFeatures
, tonicBuildVersion
, pyToml
}:
let
  protoIncludePaths = builtins.map (pi: pi.protobuf) protoInputs;
  rustInputs = builtins.map (pi: pi.rust.package.src) protoInputs;
  tonicDependencyString = ''tonic = { version = "${tonicVersion}", features = [${builtins.concatStringsSep ", " (map (v: "\"${v}\"") tonicFeatures)}] }'';
in
base.mkDerivation {
  inherit protoSources protoIncludePaths rustInputs;
  rustProtoCompiler = (base.callFile ./protobuf/compiler { inherit tonicBuildVersion; }).package;
  name = "${name}-rust-protobuf-src";

  PROTOC = "${protobuf}/bin/protoc";

  src = ./protobuf/src;

  # seem to need rustfmt, prob run on the resulting code
  nativeBuildInputs = [ rustfmt pyToml ];

  buildPhase = ''
    shopt -s extglob globstar nullglob

    includes=""
    for p in $protoIncludePaths; do
      includes+=" -I $p"
    done

    cargoDependencies=()
    externs=""
    for input in $rustInputs; do
      echo $extern
      IFS=: read name version <<< $(python ${./get_name_and_version.py} "$input")
      cargoDependencies+=("''${name} = { version=\"=''${version}\", registry=\"nix\" }")
      for f in $input/src/!(lib).rs; do
        f=''${f##*/}
        f=''${f%.rs}
        externs+="--extern .$f=\"::$name::$f\" "
      done
    done

    cargoDependencies=$( IFS=$'\n'; echo "''${cargoDependencies[*]}" )

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
      --subst-var-by external "$cargoDependencies"

    ${if includeServices then "echo 'pub use tonic;' >> ./src/lib.rs" else "" }
  '';

  installPhase = ''
    mkdir $out
    cp -r Cargo.toml src $out/
  '';
}
