{ base, python38 }:
base.languages.python.mkClient {
  name = "awesome-client";
  version = "1.0.0";
  pythonVersion = python38;
  src = ./.;
  srcExclude = [
    (path: type: (type == "directory" && baseNameOf path == "manual"))
    (path: type: (type == "regular" && baseNameOf path == "about.md"))
  ];
  docs = {
    # mkMdbook and mkDocs can take either a folder or a single file as source
    manual = base.languages.markdown.mkDocs {
      name = "client-manual";
      src = ./manual;
    };

    about = base.languages.markdown.mkSinglePage {
      name = "client-about";
      src = ./about.md;
    };
  };
}
