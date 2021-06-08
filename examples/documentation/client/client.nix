{ base, python38 }:
base.languages.python.mkClient {
  name = "awesome-client";
  version = "0.1.0";
  pythonVersion = python38;
  src = ./.;
  docs = {
    # mkMdbook and mkDocs can take either a folder or a single file as source
    manual = base.languages.markdown.mkDocs {
      name = "client-manual";
      src = ./manual;
    };
    about = base.languages.markdown.mkMdbook {
      name = "client-about";
      src = ./about.md;
    };
  };
}
