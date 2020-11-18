{ pkgs, languages }:
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
    ) // { protobuf = src; };
}
