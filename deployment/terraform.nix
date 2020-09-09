pkgs:
{
  terraformComponent = attrs@{ package, ... }: pkgs.stdenv.mkDerivation (attrs // {
    name = "terraform-deploy-${package.name}";
    buildInputs = [ package pkgs.terraform_0_13 package.buildInputs ];

    src = package.src;

    configurePhase = ''
      terraform init
    '';

    installPhase = ''
      mkdir -p $out
      export HOME="$PWD"
      terraform apply -var-file="${package}/vars.json" -auto-approve

      terraform output -json > $out/output.json
    '';
  });
}
