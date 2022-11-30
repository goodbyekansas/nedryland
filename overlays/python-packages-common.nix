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
    version = super.grpcio.version;

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "825c0c7bd01dfafe1cefd5c0aeb53aba871f40a556b00563912cd9c8837b243d";
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

  # borrowed from nixos-21.05 since ftrack has < 3
  pyparsing_2 = super.buildPythonPackage rec {
    pname = "pyparsing";
    version = "2.4.7";

    src = pkgs.fetchFromGitHub {
      owner = "pyparsing";
      repo = pname;
      rev = "pyparsing_${version}";
      sha256 = "14pfy80q2flgzjcx8jkracvnxxnr59kjzp3kdm5nh232gk1v6g6h";
    };

    # https://github.com/pyparsing/pyparsing/blob/847af590154743bae61a32c3dc1a6c2a19009f42/tox.ini#L6
    checkInputs = [ super.coverage ];
    checkPhase = ''
      coverage run --branch simple_unit_tests.py
      coverage run --branch unitTests.py
    '';
  };

  types-six = python3.pkgs.buildPythonPackage rec {
    pname = "types-six";
    version = "1.16.0";
    format = "setuptools";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-mtQh042u0rxQGnUGXA9u4qA0zEhOS8S8suLDVgpGGeQ=";
    };

    # Module doesn't have tests
    doCheck = false;

    pythonImportsCheck = [
      "six-stubs"
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
      pyparsing_2
      super.future
      super.requests
      arrow-0-15
      super.six
      super.appdirs
    ];
  };

  spacy-english = super.buildPythonPackage rec {
    name = "spacy-english";
    version = super.spacy.version;
    src = fetchzip {
      url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-${version}/en_core_web_sm-${version}.tar.gz";
      sha256 = "sha256-mNIQPbivv4/DzU6tU9iN+rRQg+nCA3Taj8sjxarMxUk=";
    };
    propagatedBuildInputs = [ super.spacy ];
  };

  # Wanddb is not passing tests in 22.05
  wandb = super.wandb.overrideAttrs (_:
    {
      disabledTestPaths = [
        # Tests that try to get chatty over sockets or spin up servers, not possible in the nix build environment.
        "tests/integrations/test_keras.py"
        "tests/integrations/test_torch.py"
        "tests/test_cli.py"
        "tests/test_data_types.py"
        "tests/test_file_stream.py"
        "tests/test_file_upload.py"
        "tests/test_footer.py"
        "tests/test_internal_api.py"
        "tests/test_label_full.py"
        "tests/test_login.py"
        "tests/test_meta.py"
        "tests/test_metric_full.py"
        "tests/test_metric_internal.py"
        "tests/test_mode_disabled.py"
        "tests/test_model_workflows.py"
        "tests/test_mp_full.py"
        "tests/test_public_api.py"
        "tests/test_redir.py"
        "tests/test_runtime.py"
        "tests/test_sender.py"
        "tests/test_start_method.py"
        "tests/test_tb_watcher.py"
        "tests/test_telemetry_full.py"
        "tests/test_util.py"
        "tests/wandb_agent_test.py"
        "tests/wandb_artifacts_test.py"
        "tests/wandb_integration_test.py"
        "tests/wandb_run_test.py"
        "tests/wandb_settings_test.py"
        "tests/wandb_sweep_test.py"
        "tests/wandb_tensorflow_test.py"
        "tests/wandb_verify_test.py"
        "tests/test_tpu.py"
        "tests/test_plots.py"
        "tests/test_profiler.py"

        # Requires metaflow, which is not yet packaged.
        "tests/integrations/test_metaflow.py"

        # Fails and borks the pytest runner as well.
        "tests/wandb_test.py"

        # Tries to access /homeless-shelter
        "tests/test_tables.py"

        # This is also bad
        "functional_tests/kfp/wandb_probe.py "
      ];
    }
  );

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
    version = "1.6.2";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "sha256-ueDDT0qGQiPveqBRMupViyt+HxBv0+QtFpEAa53KrU0=";
    };

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
    version = "3.2.0";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "sha256-3aUSBMh1NDQRZTB6CXsS5wYNK5UwyZ2yZMKsVUnFkgU=";
    };

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
      
