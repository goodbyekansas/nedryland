{ base, python38 }:
base.languages.python.mkClient rec{
  name = "awesome-client";
  version = "1.0.0";
  pythonVersion = python38;
  src = ./.;
  srcExclude = [
    (path: type: (type == "directory" && baseNameOf path == "manual"))
    (path: type: (type == "regular" && baseNameOf path == "about.md"))
  ];
  docs = {
    manual = base.documentation.mkDocs {
      name = "manuel-gearbox";
      src = ./manual;
      type = "manuel";
    };

    sharks = 5; # This value will appear in metadata.json in share/doc/awesome-client

    about = base.documentation.mkSinglePage {
      src = ./about.md;
    };
  };
}
