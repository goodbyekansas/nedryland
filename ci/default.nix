{ runCommandLocal
, nixpkgs-fmt
, diffutils
, mktemp
, shellcheck
, shfmt
, nix-linter
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
  nixLinter = "${nix-linter}/bin/nix-linter";
  bash = "${bash}/bin/bash";
  sed = "${gnused}/bin/sed";
  pyflakes = "${python3.pkgs.pyflakes}/bin/pyflakes";
  actionlint = "${actionlint}/bin/actionlint";
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
    [ ./nixfmt ./shellcheck ./nix-lint ./check ./actionlint ]
  )
