pkgs: base: attrs@{ name, type ? "user", src, ... }:
base.mkDerivation (attrs // {
  inherit name src;
  nativeBuildInputs = [ pkgs.mdbook ] ++ attrs.nativeBuildInputs or [ ];

  buildPhase = ''
    runHook preBuild
    mdbook build --dest-dir book
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/doc/${name}/${type}
    cp -r book/. $out/share/doc/${name}/${type}
    runHook postInstall
  '';
  shellHook = ''
    on_exit() {
      if [ -f ./mdbook.pid ]; then
        read -r -p "Mdbook is running, close? [Y/n] "
        case $REPLY in
          n|N|No|NO|no) ;;
          *) kill -SIGTERM $(head -n 1 ./mdbook.pid); rm ./mdbook.pid ;;
        esac
      fi
    }

    run() {
      trap on_exit SIGQUIT EXIT SIGHUP
      command run 0 ./mdbook.pid
    }

    if checkRun; then
      echo ""
      echo -e "🏃‍♀️ You seem to be running mdbook already at \e[93m$(tail -n 1 ./mdbook.pid)\e[0m, use \e[32mopen\e[0m to show it in your browser."
      echo ""
    else
      if [ -f ./mdbook.pid ]; then
        rm ./mdbook.pid
      fi
    fi

    ${attrs.shellHook or ""}
  '';
  shellCommands = {
    run = {
      script = ./mdbook-run.bash;
      description = ''
        Preview the book and watches the book's src directory for changes, rebuilding the book and refreshing clients for each change.'';
    };

    stop = {
      script = ''
        if checkRun; then
          kill -SIGTERM $(head -n 1 ./mdbook.pid)
          rm ./mdbook.pid
        else
          echo "Found no mdbook started in this shell."
        fi
      '';
      description = "Stop mdbook started in this shell.";
    };

    open = {
      script = ''
        if [ ! -f ./mdbook.pid ]; then
          run
        fi
        ${pkgs.xdg-utils}/bin/xdg-open $(tail -n 1 ./mdbook.pid) >/dev/null
      '';
      description = "Open the mdbook in your browser. Starts a mdbook serve if one isn't running already.";
    };

    checkRun = {
      script = ''[ -f ./mdbook.pid ] && [[ $(ps -o cmd= -p $(head -n 1 ./mdbook.pid)) =~ "mdbook serve" ]]'';
      show = false;
    };

    check = { show = false; };
  } // attrs.shellCommands or { };
})
