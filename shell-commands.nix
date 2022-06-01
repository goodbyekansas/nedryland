{ bash, lib, symlinkJoin, writeScriptBin }:
name:
{ build ? ''eval "$buildPhase"''
, check ? ''eval "$checkPhase"''
, run ? "echo '🏃 \"run\" not supported'"
, format ? "echo '📃 \"format\" not supported'"
, ...
}@commands:
let
  inner = cmds: symlinkJoin {
    name = "${name}-shell-commands";
    paths = lib.mapAttrsToList
      (command: script: writeScriptBin command ''
        #!${bash}/bin/bash

        envDir=$(mktemp -d -t shell-command-env.XXXXXX)

        export 2>/dev/null >| "$envDir"/shell-env

        # source setup to get functions like genericBuild for example
        # as users might expect this to exist
        NIX_BUILD_TOP=$envDir source $stdenv/setup

        # reset the shell env
        source "$envDir"/shell-env

        # need to set this to be able to have local inputs
        export NIX_ENFORCE_PURITY=0

        rm -rf "$envDir"

        ${script}
      '')
      cmds;
  };
in
# need to wrangle a little bit to get the defaults
lib.makeOverridable inner (commands // { inherit build check run format; })
