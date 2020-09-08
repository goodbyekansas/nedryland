self: super: {
  python3 = super.python3.override {
    packageOverrides = python-self: python-super: {
      jedi = python-super.jedi.overrideAttrs (oldAttrs: {
        prePatch = "";
      });
      parso = python-super.parso.overrideAttrs (oldAttrs: rec {
        version = "0.7.1";
        pname = oldAttrs.pname;
        src = python-super.fetchPypi {
          inherit version pname;
          sha256 = "caba44724b994a8a5e086460bb212abc5a8bc46951bf4a9a1210745953622eb9";
        };
      });
    };
  };
}
