self: super:
{
  python3Packages = rec {
    grpcio-testing = super.python3Packages.buildPythonPackage rec {
      pname = "grpcio-testing";
      version = "1.26.0";

      src = super.python3Packages.fetchPypi {
        inherit pname version;
        sha256 = "0svwdw824z8d49l8100qibkjgl84bpdg3jyccfidzx351nj2wal8";
      };

      doCheck = false;
      propagatedBuildInputs = [
        super.python3Packages.six
        super.python3Packages.protobuf
        super.python3Packages.grpcio
      ];
    };

    clique = super.python3Packages.buildPythonPackage rec {
      pname = "clique";
      version = "1.5.0";

      preBuild = ''
        export HOME=$PWD
      '';

      src = super.python3Packages.fetchPypi {
        inherit pname version;
        sha256 = "c34a4eac30187a5b7d75bc8cf600ddc50ceef50a423772a4c96f1dc8440af5fa";
      };

      doCheck = false;
    };

    ftrack-python-api = super.python3Packages.buildPythonPackage rec {
      pname = "ftrack-python-api";
      version = "2.0.0rc2";

      preBuild = ''
        export HOME=$PWD
      '';

      src = super.python3Packages.fetchPypi {
        inherit pname version;
        sha256 = "77e20cd7ab2d9e45edba7dbbb3404e51b9919618f83f44902aab33f1b298fdc9";
      };

      doCheck = false;
      propagatedBuildInputs = [
        clique
        super.python3Packages.termcolor
        super.python3Packages.websocket_client
        super.python3Packages.pyparsing
        super.python3Packages.future
        super.python3Packages.requests
        super.python3Packages.arrow
        super.python3Packages.six
      ];
    };

    cloudevents = super.python3Packages.buildPythonPackage rec {
      pname = "cloudevents";
      version = "0.3.0";

      src = super.python3Packages.fetchPypi {
        inherit pname version;
        sha256 = "c76e1f4341cbb7e042794bd45551c75c8e069fad30c2e29d682e978e85c7a7fb";
      };

      doCheck = false;
    };

    functions-framework = super.python3Packages.buildPythonPackage rec {
      pname = "functions-framework";
      version = "2.0.0";

      src = super.python3Packages.fetchPypi {
        inherit pname version;
        sha256 = "641bc800e480f7eec3759ca6a972753cd8bdca48aec591cdbfc65bc955f3074c";
      };

      propagatedBuildInputs = [
        cloudevents
        super.python3Packages.flask
        super.python3Packages.gunicorn
        super.python3Packages.watchdog
      ];
    };
  } // super.python3Packages;
}
