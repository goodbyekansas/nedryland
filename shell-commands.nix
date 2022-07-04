{ bash, lib, symlinkJoin, writeScriptBin }:
name:
{ build ? ''eval "$buildPhase"''
, check ? { script = ''eval "$checkPhase"''; description = "Run the checks/test."; }
, run ? { script = "echo '🏃 \"run\" not supported'"; show = false; }
, format ? { script = "echo '📃 \"format\" not supported'"; show = false; }
, ...
}@commands:
let
  # need to wrangle a little bit to get the descriptions for the shell message
  allCommands = commands // { inherit build check run format; };
  inner = cmds: symlinkJoin {
    name = "${name}-shell-commands";
    paths = lib.mapAttrsToList
      (command: script: writeScriptBin command ''
        #!${bash}/bin/bash

        envDir=$(mktemp -d -t shell-command-env.XXXXXX)

        export 2>/dev/null >| "$envDir"/shell-env

        # source setup to get functions like genericBuild for example
        # as users might expect this to exist
        NIX_BUILD_TOP=$envDir source $stdenv/setup > /dev/null

        # reset the shell env
        source "$envDir"/shell-env

        # need to set this to be able to have local inputs
        export NIX_ENFORCE_PURITY=0

        rm -rf "$envDir"

        ${if builtins.isAttrs script then script.script else script}
      '')
      cmds;
    passthru = {
      _descriptions = builtins.mapAttrs
        (_: value:
          {
            description = (if builtins.isAttrs value then value.description or "" else "");
            args = (if builtins.isAttrs value then value.args or "" else "");
            show = (if builtins.isAttrs value then value.show or true else true);
          }
        )
        allCommands;
    };
  };
in
lib.makeOverridable inner allCommands
