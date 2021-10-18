{ base, name, version, protoSources, python3, protoInputs }:
let
  protoIncludePaths = builtins.map (pi: pi.protobuf) protoInputs;
in
base.mkDerivation {
  inherit protoSources protoIncludePaths;
  name = "python-${name}";
  src = ./protobuf;
  packageName = builtins.replaceStrings [ "-" ] [ "_" ] name;
  nativeBuildInputs = with python3.pkgs; [ grpcio-tools mypy-protobuf mypy setuptools ];
  phases = [ "unpackPhase" "buildPhase" "installPhase" ];
  buildPhase = ''

    shopt -s globstar extglob nullglob

    substituteInPlace ./setup.py --subst-var-by packageName ${name} --subst-var-by version ${version}

    includes=""
    for p in $protoIncludePaths; do
      includes+=" -I $p"
    done

    python -m grpc_tools.protoc \
        -I "$protoSources" \
        $includes \
        --python_out=. \
        --grpc_python_out=. \
        --mypy_out=. \
        "$protoSources"/**/*.proto

    # protoc does not add __init__.py files, so let's do so
    find . -type d -exec touch {}/__init__.py \;
    find . -type d -exec touch {}/py.typed \;
    for pyfile in ./**/*_grpc.py; do
      stubgen $pyfile -o . --verbose

      # stubgen 0.812 outputs pyi files to a source directory
      if [ -d source ]; then
        mv source/''${pyfile}i ''${pyfile}i
        rm -rf source
      fi
      # Correcting some mistakes made by stubgen.
      # Generate static methods without return types. We just replace that with any
      # return type.
      
      sed -i -E 's/\):/\) -> Any:/' ''${pyfile}i
    done
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
