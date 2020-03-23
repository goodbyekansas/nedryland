base: { name, package, manifest }:
let
  packageWithManifest = package.overrideAttrs (
    oldAttrs: {
      installPhase = ''
        ${oldAttrs.installPhase}
         cp ${manifest} $out/manifest.toml
      '';
    }
  );
in
base.mkComponent {
  package = packageWithManifest;
  deployment = base.deployment.deployFunction { package = packageWithManifest; };
}
