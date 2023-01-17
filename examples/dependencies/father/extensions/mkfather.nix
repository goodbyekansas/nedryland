{ base }:
{
  languages = {
    ewokese = {
      mkFather = { name, childName ? "" }:
        base.mkComponent {
          inherit name;
          nedrylandType = "father";
          father = base.mkDerivation {
            inherit name childName;
            builder = builtins.toFile "builder.sh" ''
              echo "$name: $childName I am your father!" > $out
            '';
          };
        };
    };
  };
}
