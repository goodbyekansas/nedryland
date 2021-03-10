{ base, pkgs }:
let
  mkPackage = pkgs.callPackage ./package.nix { inherit base; };

  # use `stdenv` to override mkPackage
  # if it is part of attrs
  mkPackageOverrideStdenv = attrs:
    let
      mkPackage' =
        if attrs ? stdenv then
          mkPackage.override
            {
              stdenv = attrs.stdenv;
            }
        else mkPackage;
    in
    mkPackage' attrs;
in
rec {
  inherit mkPackage;

  toApplication = package:
    package.overrideAttrs (
      oldAttrs: {
        installPhase = ''
          ${oldAttrs.installPhase}
          mkdir -p $out/bin
          cp target/${package.defaultTarget or ""}/release/${package.executableName or package.meta.name}${
            if pkgs.lib.hasInfix "-windows-" package.defaultTarget or "" then
              ".exe"
            else
              ""
          } $out/bin
        '';
      }
    );

  toLibrary = package:
    let
      checksumHook = pkgs.makeSetupHook
        {
          name = "generate-cargo-checksums";
          deps = [ pkgs.jq pkgs.coreutils ];
        }
        ./generateCargoChecksums.sh;
    in
    package.overrideAttrs (
      oldAttrs: {

        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ checksumHook ];
        buildPhase = ''
          runHook preBuild
          cargo package --no-verify --no-metadata
          runHook postBuild
        '';

        installPhase = ''
          mkdir -p $out/src/rust

          for crate in target/package/*.crate; do
            tar -xzf $crate -C $out/src/rust
          done
        '';
      }
    );

  mkLibrary =
    attrs@
    { name
    , src
    , deployment ? { }
    , ...
    }:
    let
      package = toLibrary (mkPackageOverrideStdenv (
        (builtins.removeAttrs attrs [ "deployment" ]) // {
          filterCargoLock = true;
        }
      ));
    in
    base.mkComponent {
      inherit deployment name package;
      rust = package;
    };

  mkClient =
    attrs@
    { name
    , src
    , deployment ? { }
    , ...
    }:
    let
      package = toApplication (mkPackageOverrideStdenv (builtins.removeAttrs attrs [ "deployment" ]));
    in
    base.mkClient {
      inherit deployment name package;
      rust = package;
    };

  mkService =
    attrs@
    { name
    , src
    , deployment ? { }
    , ...
    }:
    let
      package = toApplication (mkPackageOverrideStdenv (builtins.removeAttrs attrs [ "deployment" ]));
    in
    base.mkService {
      inherit deployment name package;
      rust = package;
    };

  fromProtobuf = { name, protoSources, version, includeServices, protoInputs }:
    let
      generatedCode = pkgs.callPackage ./protobuf.nix { inherit name protoSources version mkClient includeServices protoInputs; };
    in
    mkLibrary { inherit name version; src = generatedCode; propagatedBuildInputs = builtins.map (pi: pi.rust.package) protoInputs; };
}
