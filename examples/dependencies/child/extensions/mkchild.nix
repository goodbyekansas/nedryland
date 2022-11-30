{ base }:
{
  languages = {
    ewokese = {
      mkChild = attrs@{ name, ... }:
        (base.languages.ewokese.mkFather {
          name = "Darth-Vader";
          childName = name;
        }) // attrs;
    };
  };
}
