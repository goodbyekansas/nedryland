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

        export 2>/dev/null >| $NIX_BUILD_TOP/shell-env

        # source setup to get functions like genericBuild for example
        # as users might expect this to exist
        source $stdenv/setup

        # reset the shell env
        source $NIX_BUILD_TOP/shell-env

        # need to set this to be able to have local inputs
        export NIX_ENFORCE_PURITY=0

        ${script}
      '')
      cmds;
  };
in
# need to wrangle a little bit to get the defaults
lib.makeOverridable inner (commands // { inherit build check run format; })
