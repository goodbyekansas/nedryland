pkgs: rec {
  static = { name, cfg, path ? null, vars ? { } }:
    dynamic {
      inherit name cfg path vars;
      image = null;
    };

  dynamic = { name, cfg, image, path ? null, vars ? { } }:
    let
      f = { cfg, name, image, path, vars }:
        let
          cfgContent = if builtins.isPath cfg then builtins.readFile cfg else cfg;
          imageAndVersion = {
            file_version =
              builtins.substring 0 10 (builtins.hashString "sha256" cfgContent);
            image_version =
              if image != null then
                builtins.substring 0 32 (builtins.baseNameOf "${image}")
              else
                "";
            image =
              if image != null then
                "${image.imageName}:${image.imageTag}"
              else
                "";
          };
          j2 = pkgs.python3.withPackages (ps: with ps; [ j2cli setuptools ]);
        in
        rec {
          inherit image;
          inputVars = vars;
          descriptor = { inherit name path; };

          cfg = cfgContent;

          pkg = pkgs.stdenv.mkDerivation {
            name = "${name}-k8s";

            inherit cfgContent;
            buildInputs = [ j2 ];
            jsonVars = builtins.toJSON (
              (if builtins.isFunction inputVars then { } else vars)
              // imageAndVersion
            );

            passAsFile = [ "cfgContent" "jsonVars" ];


            builder = builtins.toFile "builder.sh" ''
              source $stdenv/setup
              mkdir $out

              j2 -f json "$cfgContentPath" "$jsonVarsPath" --customize ${
                ./jinja_addons.py
              } -o $out/${name}.yaml
            '';
          };
        };
      # make sure we can override this function later with
      # different arguments
    in
    pkgs.makeOverridable f { inherit name cfg image path vars; };

}
