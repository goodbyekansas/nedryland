pkgs:
{

  terraformModule = { package }: pkgs.stdenv.mkDerivation {
    name = "terraform-deploy-${package.name}";
    buildInputs = [ package ];

    src = package.src;

    configurePhase = ''
      terraform init
    '';

    buildPhase = ''
      terraform apply -auto-approve ${package}/plan
    '';
  }
}
