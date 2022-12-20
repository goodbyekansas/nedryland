{ base, writeScriptBin }:
base.mkLibrary rec{
  name = "greetingLib";
  version = "1.0.0";

  lib = writeScriptBin name ''
    case $1 in
      swedish) echo "hej";;
      english) echo "hello";;
      french) echo "bonjour";;
      finnish) echo "hyvää päivää";;
      finish) echo "🏁";;
      *) >&2 echo "Unknown language $1"; exit 1;;
    esac
  '';
}
