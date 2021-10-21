_: super:
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
  fetchFromGitHub = super.fetchFromGitHub;
  tzdata = super.tzdata;

  wheelHook = super.makeSetupHook { name = "copyWheelHook"; } ../languages/python/wheelHook.bash;
in
(builtins.foldl'
  (combined: pythonVersion:
    (combined // {
      # pkgs.<python-version>.pkgs
      "${pythonVersion.attr}" = pythonVersion.pkg.override {
        packageOverrides = _: super: rec {

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

          # Borrowed from nixpkgs 20.09 for ftrack which has an upper version limit
          arrow-0-15 = super.buildPythonPackage rec {
            pname = "arrow";
            version = "0.15.8";

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "edc31dc051db12c95da9bac0271cd1027b8e36912daf6d4580af53b23e62721a";
            };

            propagatedBuildInputs = [ super.dateutil ];

            checkInputs = [
              super.dateparser
              super.pytestCheckHook
              super.pytestcov
              super.pytest-mock
              super.pytz
              super.simplejson
              super.sphinx
            ];

            # ParserError: Could not parse timezone expression "America/Nuuk"
            disabledTests = [
              "test_parse_tz_name_zzz"
            ];
          };

          ftrack-python-api = super.buildPythonPackage rec {
            pname = "ftrack-python-api";
            version = "2.2.0";

            preBuild = ''
              export HOME=$PWD
            '';

            src = super.fetchPypi {
              inherit pname version;
              sha256 = "13d4vg5p0k63nmv9raax1jd8gmswlj1ibf4md0kb8gcr8kdq0imi";
            };

            doCheck = false;
            propagatedBuildInputs = [
              clique
              super.termcolor
              super.websocket_client
              super.pyparsing
              super.future
              super.requests
              arrow-0-15
              super.six
              super.appdirs
            ];
          };

          spacy-english = super.buildPythonPackage rec {
            name = "spacy-english";
            version = "3.0.0";
            src = fetchzip {
              url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-${version}/en_core_web_sm-${version}.tar.gz";
              sha256 = "0bd3i104pk9w3cq8pv7n3hm9qq66l4cvk8bpms9wrivh5xpg6fsk";
            };
            propagatedBuildInputs = [ super.spacy ];
          };

          pdoc = super.buildPythonPackage rec {
            pname = "pdoc";
            version = "7.1.1";
            src = fetchzip {
              url = "https://github.com/mitmproxy/pdoc/archive/refs/tags/v7.1.1.tar.gz";
              sha256 = "1rxxkg94qflcnh05gp5fs025jd7vriqb20y9qs7xr542rhbajhxw";
            };
            propagatedBuildInputs = [ super.jinja2 super.pygments super.markupsafe super.astunparse ];
            doCheck = false;
          };

          babel = super.buildPythonPackage rec {
            pname = "Babel";
            version = "2.9.1";
            src = super.fetchPypi {
              inherit pname version;
              sha256 = "bc0c176f9f6a994582230df350aa6e05ba2ebe4b3ac317eab29d9be5d2768da0";
            };
            propagatedBuildInputs = [ super.pytz ];
            doCheck = false;
          };

          # Sphinx and sphinx_rtd_theme is on a custom branch to work with logos on the internet
          sphinx4 = super.buildPythonPackage rec {
            pname = "Sphinx4";
            version = "4.0.2";
            src = fetchFromGitHub {
              owner = "goodbyekansas";
              repo = "Sphinx";
              rev = "d16631791bb8288968834b6afcbcf9b805c17e74";
              sha256 = "02jh5vb2v7ydrswp17k4fjwfz2dnil1g4g7v3mcq4di5k9357r9k";
            };
            propagatedBuildInputs = [
              super.jinja2
              super.pygments
              super.docutils
              super.snowballstemmer
              super.sphinxcontrib-applehelp
              super.sphinxcontrib-devhelp
              super.sphinxcontrib-jsmath
              super.sphinxcontrib-htmlhelp
              super.sphinxcontrib-serializinghtml
              super.sphinxcontrib-qthelp
              babel
              super.alabaster
              super.imagesize
              super.requests
              super.setuptools
              super.packaging
            ];
            doCheck = false;
          };

          sphinx4_rtd_theme = super.buildPythonPackage {
            pname = "sphinx4_rtd_theme";
            version = "0.5.2";
            src = fetchFromGitHub {
              owner = "goodbyekansas";
              repo = "sphinx_rtd_theme";
              rev = "c4baa88e42b49c7a0593d330cb51547e4dc8bd53";
              sha256 = "0mvsnfh0lxd1s0ddnlwalmnrrybz6dx77vn4qq79ifz7n2yfd0gd";
            };

            CI = 1; # Don't use NPM to fetch assets. Assets are included in sdist.
            propagatedBuildInputs = [ sphinx4 super.docutils ];
          };

          keepachangelog = super.buildPythonPackage rec{
            pname = "keepachangelog";
            version = "2.0.0.dev1";

            src = fetchFromGitHub {
              owner = "Colin-b";
              repo = pname;
              rev = "82523116d91c7009a28fa3c082d790891e441ebd";
              sha256 = "0fx9i17l6c6i58vcglvafpkqbwn9xw81c623sy0qvga78x90y5c6";
            };
            doCheck = false;
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
          python-language-server = super.python-language-server.overrideAttrs (_:
            (if isDarwin then {
              doCheck = false;
              doInstallCheck = false;
            } else { }));
        };
      };

      # pkgs.<python-version>Packages
      "${pythonVersion.attr}Packages" = pythonVersion.pkg.pkgs;
    })
  )
  { }
  pythonVersions
)
