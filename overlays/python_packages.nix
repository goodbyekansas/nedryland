self: super:
let
  pythonVersions = [
    {
      pkg = super.python38;
      attr = "python38";
    }
    {
      pkg = super.python37;
      attr = "python37";
    }
  ];
  isDarwin = super.stdenv.isDarwin;
in
(builtins.foldl'
  (combined: pythonVersion:
    (combined // rec {
      # pkgs.<python-version>.pkgs
      "${pythonVersion.attr}" = pythonVersion.pkg.override {
        packageOverrides = self: super: rec {

          grpcio-testing = super.buildPythonPackage rec {
            pname = "grpcio-testing";
            version = "1.26.0";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "0svwdw824z8d49l8100qibkjgl84bpdg3jyccfidzx351nj2wal8";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            doCheck = false;
            propagatedBuildInputs = [
              super.six
              super.protobuf
              super.grpcio
            ];
          };

          clique = super.buildPythonPackage rec {
            pname = "clique";
            version = "1.5.0";

            preBuild = ''
              export HOME=$PWD
            '';

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "c34a4eac30187a5b7d75bc8cf600ddc50ceef50a423772a4c96f1dc8440af5fa";
            };

            doCheck = false;
          };

          ftrack-python-api = super.buildPythonPackage rec {
            pname = "ftrack-python-api";
            version = "2.0.0rc2";

            preBuild = ''
              export HOME=$PWD
            '';

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "77e20cd7ab2d9e45edba7dbbb3404e51b9919618f83f44902aab33f1b298fdc9";
            };

            doCheck = false;
            propagatedBuildInputs = [
              clique
              super.termcolor
              super.websocket_client
              super.pyparsing
              super.future
              super.requests
              super.arrow
              super.six
            ];
          };

          cloudevents = super.buildPythonPackage rec {
            pname = "cloudevents";
            version = "0.3.0";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "c76e1f4341cbb7e042794bd45551c75c8e069fad30c2e29d682e978e85c7a7fb";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            doCheck = false;
          };

          functions-framework = super.buildPythonPackage rec {
            pname = "functions-framework";
            version = "2.0.0";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "641bc800e480f7eec3759ca6a972753cd8bdca48aec591cdbfc65bc955f3074c";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            propagatedBuildInputs = [
              cloudevents
              super.flask
              super.gunicorn
              super.watchdog
            ];
          };

          # these tests seems broken for python 3.8 on macos
          # https://hydra.nixos.org/job/nixpkgs/nixpkgs-20.09-darwin/python38Packages.python-language-server.x86_64-darwin
          python-language-server = super.python-language-server.overrideAttrs (oldAttrs: {
            doCheck = !isDarwin;
            doInstallCheck = !isDarwin;
          });

        };
      };

      # pkgs.<python-version>Packages
      "${pythonVersion.attr}Packages" = pythonVersion.pkg.pkgs;
    })
  )
  { }
  pythonVersions
)
