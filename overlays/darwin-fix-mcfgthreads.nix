_: super:

# this is not a proper fix but gets us going
# issue here: https://github.com/NixOS/nixpkgs/issues/97214
if super.stdenv.buildPlatform.isDarwin then {
  windows = super.windows // {
    mcfgthreads = super.windows.mcfgthreads.overrideAttrs (_: {
      postPatch = ''
        substituteInPlace Makefile.am --replace "-Werror" ""
      '';
    });
  };
} else { }
