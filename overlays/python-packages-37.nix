_pkgs: super:
{
  astroid = super.astroid.overrideAttrs (meteor: {
    patches = meteor.patches or [ ] ++ [ ./python-patches/astroid-setup-cfg.patch ];
  });

  flake8 = super.flake8.overrideAttrs (orig: {
    patches = orig.patches or [ ] ++ [ ./python-patches/flake8-setup-cfg.patch ];
  });
}
