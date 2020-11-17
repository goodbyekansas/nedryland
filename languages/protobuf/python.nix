{ stdenv, name, version, protoSources, python3 }:
stdenv.mkDerivation {
  inherit protoSources;
  name = "python-${name}";
  src = ./python;
  packageName = builtins.replaceStrings [ "-" ] [ "_" ] name;
  nativeBuildInputs = with python3.pkgs; [ grpcio-tools mypy-protobuf mypy setuptools ];
  phases = [ "unpackPhase" "buildPhase" "installPhase" ];
  buildPhase = ''
    mkdir -p ./$packageName

    substitute ./setup.py.in ./setup.py --subst-var-by packageName ${name} --subst-var-by version ${version}

    python -m grpc_tools.protoc \
        -I "$protoSources" \
        --python_out=./$packageName \
        --grpc_python_out=./$packageName \
        --mypy_out=./$packageName \
        "$protoSources"/**/*.proto

    # protoc does not add __init__.py files, so let's do so
    find ./$packageName -type d -exec touch {}/__init__.py \;
    find ./$packageName -type d -exec touch {}/py.typed \;

    shopt -s globstar
    shopt -s extglob
    shopt -s nullglob

    for pyfile in ./$packageName/**/*_grpc.py; do
      stubgen $pyfile -o .
      # Correcting some mistakes made by stubgen.
      # Generate static methods without return types. We just replace that with any return type.
      sed -i -E 's/\):/\) -> Any:/' ''${pyfile}i
    done

    # correct the imports since that is apparently impossible to do correctly
    sed -i -E "s/^from (\S* import .*_pb2)/from $packageName.\1/ " $packageName/**/*.py
    sed -i -E "s/^from (\S* import .*_pb2)/from $packageName.\1/ " $packageName/**/*.pyi
    sed -i -E "s/^from (\S*.*_pb2)/from $packageName.\1/ " $packageName/**/*.pyi
  '';

  installPhase = ''
    mkdir -p $out
    cp -r ./$packageName ./setup.py $out
  '';
}
