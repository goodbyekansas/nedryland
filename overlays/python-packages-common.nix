pkgs: super:
with pkgs;
rec {
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

  qt-dot-py = super.buildPythonPackage rec {
    pname = "Qt.py";
    version = "1.3.6";

    preBuild = ''
      export HOME=$PWD
    '';

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "0jj09hlj8xf728vq7cqq910yq36symxiqlh4wgp04il15xm6ay0d";
    };

    doCheck = false;
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

  timecode = super.buildPythonPackage rec {
    pname = "timecode";
    version = "1.3.1";

    preBuild = ''
      export HOME=$PWD
    '';

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "1fh7chx9flqb4c5lfv953dxk1542slwc0237vayin7king2gvpc4";
    };

    doCheck = false;
  };

  markdown-include = super.buildPythonPackage rec {
    pname = "markdown-include";
    version = "0.6.0";

    preBuild = ''
      export HOME=$PWD
    '';

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "18p4qfhazvskcg6xsdv1np8m1gc1llyabp311xzhqy7p6q76hpbg";
    };

    doCheck = false;

    propagatedBuildInputs = [
      super.markdown
    ];
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
    version = "2.3.3";

    preBuild = ''
      export HOME=$PWD
    '';

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "358f37e5b1c5635eab107c19e27a0c890d512877f78af35b1ac416e90c037295";
    };

    doCheck = false;
    propagatedBuildInputs = [
      clique
      super.termcolor
      (super.buildPythonPackage rec {
        pname = "websocket_client";
        version = "0.58.0";

        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-Y1CbQdFYrlt/Z+tK0g/su07umUNOc+FANU3D/44JcW8=";
        };

        propagatedBuildInputs = [ super.six ];

        checkInputs = [ super.pytestCheckHook ];

        pythonImportsCheck = [ "websocket" ];
      }
      )
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
    version = "3.1.0";
    src = fetchzip {
      url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-${version}/en_core_web_sm-${version}.tar.gz";
      sha256 = "sha256-a7dEDNLAXv867aL9eRw3Peojg0zPzC+qUVYKunllEEc=";
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

  keyrings-google-artifactregistry-auth = super.buildPythonPackage rec {
    pname = "keyrings.google-artifactregistry-auth";
    version = "0.0.3";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "0dfvr7k3q1422ls11h1957dpj9c7djd6ppb2pjzph5svfp0rpxjl";
    };
    doCheck = false;
    propagatedBuildInputs = with super; [
      keyring
      google-auth
      requests
      pluggy
    ];
  };

  cloudevents = super.buildPythonPackage rec {
    pname = "cloudevents";
    version = "1.2.0";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "sha256-zd8VxfKagMJUsVIRcPrjZ8WCiwJVwu+E46pMXwLkTA8=";
    };

    # Cloudevents does not package its packaing file
    # https://github.com/cloudevents/sdk-python/issues/133
    pypiPackaging = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/cloudevents/sdk-python/390f5944c041d02979ecc403fb17fd49f4465b7a/pypi_packaging.py";
      hash = "sha256-6GunKVAR+614mytmYDQwX5/w+A/5kbhmgC/inopn/6k=";
    };

    postUnpack = ''
      cp $pypiPackaging cloudevents-1.2.0/pypi_packaging.py
    '';

    propagatedBuildInputs = [
      super.deprecation
    ];

    preBuild = ''
      export HOME=$PWD
    '';

    doCheck = false;
  };

  functions-framework = super.buildPythonPackage rec {
    pname = "functions-framework";
    version = "3.0.0";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "sha256-QiqnLFTF4mB2404HTq3z5xNZWiWzh+xRBoqnuZUqUEc=";
    };

    patches = [ ./python-patches/functions-framework-setup.py ];

    preBuild = ''
      export HOME=$PWD
    '';

    propagatedBuildInputs = [
      cloudevents
      super.click
      super.flask
      super.gunicorn
      super.watchdog
    ];
  };
}
      
