{ base, writeScriptBin }:
base.mkLibrary rec{
  name = "greetinglib";
  version = "1.0.0";
  lib = writeScriptBin name ''
    case $1 in
      swedish) echo "hej";;
      english) echo "hello";;
      french) echo "bonjour";;
      finish) echo "hyvää päivää";;
      *) >&2 echo "Unknown language $1"; exit 1;;
    esac
  '';
}
