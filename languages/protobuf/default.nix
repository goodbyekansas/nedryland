{ base, pkgs, languages }:
let
  allLanguages = builtins.attrValues languages;
in
{
  mkModule =
    { name
    , src
    , version
    , languages ? allLanguages
    , pythonVersion ? pkgs.python3
    , includeServices ? false
    , protoInputs ? [ ]
    }:
    let
      args = {
        inherit name languages version includeServices pythonVersion protoInputs; protoSources = src;
      };
      supportedLanguages = builtins.filter (value: value ? fromProtobuf) languages;
    in
    (builtins.listToAttrs
      (builtins.map
        (lang:
        {
          name = lang.name;
          value =
            lang.fromProtobuf (
              builtins.intersectAttrs
                (
                  builtins.functionArgs lang.fromProtobuf
                )
                args
            );
        })
        supportedLanguages
      )
    ) // {
      protobuf = src;
      docs.api = base.mkDerivation {
        name = "${name}-generated-docs";
        inherit src;
        protoIncludePaths = builtins.map (pi: pi.protobuf) protoInputs;
        nativeBuildInputs = with pkgs;[ grpc-tools protoc-gen-doc ];
        builder = builtins.toFile "builder.sh" ''
          source $stdenv/setup
          includes=""
          for p in $protoIncludePaths; do
            includes+=" -I $p"
          done
          mkdir -p "$out/share/doc/${name}/api"
          protoc --proto_path=$src $includes --doc_out="$out/share/doc/${name}/api/" --doc_opt=html,index.html $(find $src -name "*.proto" -print)
        '';
      };
    };
}
