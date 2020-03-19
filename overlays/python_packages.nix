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
  } // super.python3Packages;
}
