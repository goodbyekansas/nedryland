pkgs: mkComponent:
pkgs.lib.makeOverridable (targets: ({
  _isNedrylandCombinedDocs = true;
  resolve = (name:
    let
      resolvedDocDrvs = builtins.mapAttrs
        (key: func:
          func.docFunction name key)
        (pkgs.lib.filterAttrs (_: v: builtins.isAttrs v && v ? docFunction) targets);
      attrsWithResolvedDocDrvs = targets // resolvedDocDrvs;
    in
    mkComponent
      (attrsWithResolvedDocDrvs // {
        inherit name;
        all = pkgs.symlinkJoin {
          name = "${name}-all-documentation";
          paths = builtins.attrValues resolvedDocDrvs ++ (builtins.filter pkgs.lib.isDerivation (builtins.attrValues targets));
          postBuild = ''
            mkdir -p $out/share/doc/${name}/
            echo '${builtins.toJSON  attrsWithResolvedDocDrvs}' > $out/share/doc/${name}/metadata.json
          '';
        };
        nedrylandType = "documentation";
      }));
} // pkgs.lib.optionalAttrs (targets ? "name") { inherit (targets) name; }))
