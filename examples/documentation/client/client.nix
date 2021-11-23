{ base, python38 }:
base.languages.python.mkClient {
  name = "awesome-client";
  version = "1.0.0";
  pythonVersion = python38;
  src = ./.;
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
