{ runCommandLocal
, nixpkgs-fmt
, diffutils
, mktemp
, shellcheck
, shfmt
, statix
, bash
, gnused
, python3
, actionlint
}:
runCommandLocal "check"
{
  nixpkgsFmt = "${nixpkgs-fmt}/bin/nixpkgs-fmt";
  diff = "${diffutils}/bin/diff";
  mktemp = "${mktemp}/bin/mktemp";
  shellcheck = "${shellcheck}/bin/shellcheck";
  shfmt = "${shfmt}/bin/shfmt";
  nixLinter = "${statix}/bin/statix";
  bash = "${bash}/bin/bash";
  sed = "${gnused}/bin/sed";
  pyflakes = "${python3.pkgs.pyflakes}/bin/pyflakes";
  actionlint = "${actionlint}/bin/actionlint";
  preamble = ''
    if [[ ",''${NEDRYLAND_NO_USE_CHECK_FILES:-}," =~ ",$(basename "$0")," ]]; then
      echo "forcing file list off for tool \"$(basename "$0")\""
      unset NEDRYLAND_CHECK_FILES
    fi
  '';
}
  (builtins.foldl'
    (buildScript: inputScript:
    let
      outputScript = "${(builtins.placeholder "out")}/bin/${builtins.head (builtins.split "\\\." (builtins.baseNameOf inputScript))}";
    in
    ''
      ${buildScript}
      mkdir -p "$(dirname "${outputScript}")"
      substituteAll ${inputScript} ${outputScript}
      chmod +x ${outputScript}
    ''
    )
    ""
    [ ./nixfmt ./shellcheck ./nixlint ./check ./actionlint ]
  )
