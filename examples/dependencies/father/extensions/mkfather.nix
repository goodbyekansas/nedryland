{ base }:
{
  languages = {
    ewokese = {
      mkFather = { name, childName ? "" }:
        base.mkDerivation {
          inherit name childName;
          builder = builtins.toFile "builder.sh" ''
            echo "$name: $childName I am your father!" > $out
          '';
        };
    };
  };
}
