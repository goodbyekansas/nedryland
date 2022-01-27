{ base }:
base.languages.rust.mkService {
  name = "awesome-service";
  version = "1.0.0";
  src = ./.;
  docs = {
    # mkProjectDocs uses the function named in the project config
    installInstructions = base.documentation.mkProjectDocs {
      name = "install-instructions";
      src = ./docs;
    };
  };
}
