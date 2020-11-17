{ pkgs, rust, python }:
let
  supportedLanguages = [ "rust" "python" ];
in
rec {
  generateCode = { name, src, version, languages ? supportedLanguages, includeServices ? false }:
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
              inherit name rust includeServices version;
              protoSources = invariantSource;
            };
          in
          {
            "name" = l;
            "value" = pkgs.callPackage f args;
          })
        languages
    );

  mkModule = { name, src, version, languages ? supportedLanguages, pythonVersion ? pkgs.python3 }:
    let
      withServices = generateCode { inherit name src languages version; includeServices = true; };
      onlyMessages = generateCode { inherit name src languages version; includeServices = false; };
    in
    {
      python = python.mkUtility {
        inherit name version pythonVersion;
        src = withServices.python;
        propagatedBuildInputs = (pypkgs: [ pypkgs.grpcio ]);
        doStandardTests = false; # We don't want to run our strict tests on generated code and stubs
      };

      rust = {
        withServices = rust.mkUtility { inherit name version; src = withServices.rust; };
        onlyMessages = rust.mkUtility { inherit name version; src = onlyMessages.rust; };
      };
    };

}
