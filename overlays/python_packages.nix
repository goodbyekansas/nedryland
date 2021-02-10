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
  fetchzip = super.fetchzip;
in
(builtins.foldl'
  (combined: pythonVersion:
    (combined // rec {
      # pkgs.<python-version>.pkgs
      "${pythonVersion.attr}" = pythonVersion.pkg.override {
        packageOverrides = self: super: rec {

          pycue = super.buildPythonPackage rec {
            pname = "pycue";
            version = "0.4.95";

            src = fetchzip {
              url = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v0.4.95/pycue-0.4.95-all.tar.gz";
              sha256 = "0f1r0y5n5rzk922a24146qjbd7dxjf8f34cgrk7nsfyk8aqhh6np";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            checkInputs = [
              super.mock
            ];

            propagatedBuildInputs = [
              super.grpcio
              super.pyyaml
              super.future
            ];
          };

          pyoutline = super.buildPythonPackage rec {
            pname = "pyoutline";
            version = "0.4.95";

            src = fetchzip {
              url = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v0.4.95/pyoutline-0.4.95-all.tar.gz";
              sha256 = "07lmbclfaihddy26sajnfghyiqh69v260swpxrb961kb6iv19zqn";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            # TODO: check on this
            doCheck = false;
            #preCheck = ''
            # export HOME=$(mktemp --tmpdir -d pyoutline-tests-home.XXXXX)
            #'';

            checkInputs = [
              super.mock
            ];

            propagatedBuildInputs = [
              super.pyyaml
              super.future
              super.six
              pycue
            ];
          };

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
          python-language-server = super.python-language-server.overrideAttrs (oldAttrs:
            (if isDarwin then {
              doCheck = false;
              doInstallCheck = false;
            } else { }));

          pytest-pylint = super.pytest-pylint.overrideAttrs (oldAttrs: rec {
            version = "0.18.0";
            src = super.fetchPypi {
              pname = oldAttrs.pname;
              inherit version;
              sha256 = "790c7a8019fab08e59bd3812db1657a01995a975af8b1c6ce95b9aa39d61da27";
            };
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
