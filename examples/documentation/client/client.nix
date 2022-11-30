{ base }:
base.mkClient rec{
  name = "awesome-client";
  version = "1.0.0";
  src = null;

  docs = {
    manual = base.documentation.mkDocs {
      name = "client-docs";
      src = ./manual;
      type = "manuel";
    };

    sharks = 5; # This value will appear in metadata.json in share/doc/awesome-client

    about = base.documentation.mkSinglePage {
      src = ./about.md;
    };
  };
}
