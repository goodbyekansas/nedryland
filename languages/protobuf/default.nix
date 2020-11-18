{ pkgs, rust, python }:
let
  supportedLanguages = [ "rust" "python" ];
in
rec {
  generateCode = { name, src, version, languages ? supportedLanguages, includeServices ? false, protoIncludePaths ? [ ] }:
    let
      invariantSource = if pkgs.lib.isStorePath src then src else builtins.path { path = src; inherit name; };
    in
    builtins.listToAttrs (
      builtins.map
        (l:
          let
            p = ./. + "/${l}.nix";
            f = if builtins.pathExists p then (import p) else builtins.abort "👺 Language ${l} is not supported";
            args = builtins.intersectAttrs (builtins.functionArgs f) {
              inherit name rust includeServices version protoIncludePaths;
              protoSources = invariantSource;
            };
          in
          {
            "name" = l;
            "value" = pkgs.callPackage f args;
          })
        languages
    );

  mkModule = { name, src, version, languages ? supportedLanguages, pythonVersion ? pkgs.python3, includeServices ? false, protoInputs ? [ ] }:
    let
      generatedCode = generateCode {
        inherit name src languages version includeServices;
        protoIncludePaths = builtins.map (pi: pi.protobuf) protoInputs;
      };
    in
    {
      protobuf = src;
      python = python.mkUtility {
        inherit name version pythonVersion;
        src = generatedCode.python;
        propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ] ++ builtins.map (pi: pi.python.package) protoInputs);
        doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
      };

      rust = rust.mkUtility {
        inherit name version;
        src = generatedCode.rust;
      };
    };

}
