{ base }:
base.mkService {
  name = "awesome-service";
  version = "1.0.0";

  docs = {
    # mkProjectDocs uses the function named in the project config
    installInstructions = base.documentation.mkProjectDocs {
      name = "install-instructions";
      src = ./docs;
    };
  };
}
