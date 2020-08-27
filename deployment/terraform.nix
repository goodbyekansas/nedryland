pkgs:
{
  terraformComponent = attrs@{ package, ... }: pkgs.stdenv.mkDerivation (attrs // {
    name = "terraform-deploy-${package.name}";
    buildInputs = [ package pkgs.terraform_0_13 ];

    src = package.src;

    configurePhase = ''
      terraform init
    '';

    installPhase = ''
      mkdir -p $out
      terraform apply -auto-approve

      terraform output -json > $out/output.json
    '';
  });
}
