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
  tzdata = super.tzdata;

  wheelHook = super.makeSetupHook { name = "copyWheelHook"; } ../languages/python/wheelHook.sh;
in
(builtins.foldl'
  (combined: pythonVersion:
    (combined // rec {
      # pkgs.<python-version>.pkgs
      "${pythonVersion.attr}" = pythonVersion.pkg.override {
        packageOverrides = self: super: rec {

          quadprog = super.buildPythonPackage rec {
            pname = "quadprog";
            version = "0.1.8";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "01qb6p1ybv9sd01v5jy85kkzkyq3iqia2ds0b0l7in19d4vgkv9x";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            nativeBuildInputs = [
              super.cython
            ];
          };

          trimesh = super.buildPythonPackage rec {
            pname = "trimesh";
            version = "3.9.7";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "1qsiypqh83sb3hx07x0jn3cvygrxx1qvj282w19xsvac399pdpb3";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            doCheck = false;
            nativeBuildInputs = [
              super.numpy
            ];
          };

          pycue = super.buildPythonPackage rec {
            pname = "pycue";
            version = "0.8.8";

            src = fetchzip {
              url = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v0.8.8/pycue-0.8.8-all.tar.gz";
              sha256 = "1vvlndw8gx7sbcqffrh1a6aa1087473fycrj4vkk9zdi4zddyxx6";
            };

            preBuild = ''
              export HOME=$PWD
            '';

            checkInputs = [
              super.mock
              tzdata
            ];

            propagatedBuildInputs = [
              super.future
              super.grpcio
              super.pyyaml
            ];

            # create a wheel for this since it does not come from pypi
            buildInputs = [ wheelHook ];
          };

          pyoutline = super.buildPythonPackage rec {
            pname = "pyoutline";
            version = "0.8.8";

            src = fetchzip {
              url = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v0.8.8/pyoutline-0.8.8-all.tar.gz";
              sha256 = "0kbb47wv7i3y1kp2mq0lrwg8glaj6s5gv2dck41wmy8wah3vf42r";
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
              super.packaging
              super.six
              pycue
            ];

            # create a wheel for this since it does not come from pypi
            buildInputs = [ wheelHook ];
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
            version = "1.6.1";

            preBuild = ''
              export HOME=$PWD
            '';

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "90165c1cf162d4dd1baef83ceaa1afc886b453e379094fa5b60ea470d1733e66";
            };

            doCheck = false;
          };

          ftrack-python-api = super.buildPythonPackage rec {
            pname = "ftrack-python-api";
            version = "2.1.1";

            preBuild = ''
              export HOME=$PWD
            '';

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "1d33793beac356360e89c95aaf9886128929827a16ddad6c52183a94b542b42a";
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
              super.appdirs
            ];
          };

          spacy-english = super.buildPythonPackage {
            name = "spacy-english";
            version = "2.3.1";
            src = fetchzip {
              url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-2.3.1/en_core_web_sm-2.3.1.tar.gz";
              sha256 = "0x47f6vkh81hcffs5fk4xrlcyrcssgisw85cw5m2829sv8x8mmqg";
            };
            propagatedBuildInputs = [ super.spacy ];
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
