pkgs:
{
  terraformComponent = attrs@{ package, ... }: pkgs.stdenv.mkDerivation (attrs // {
    name = "terraform-deploy-${package.name}";
    buildInputs = [ package pkgs.terraform_0_13 package.buildInputs ];

    src = package.src;

    configurePhase = ''
      terraform init -lock-timeout=300s
    '';

    installPhase = ''
      mkdir -p $out
      export HOME="$PWD"
      terraform apply -var-file="${package}/vars.json" -auto-approve -lock-timeout=300s

      terraform output -json > $out/output.json
    '';
  });
}
