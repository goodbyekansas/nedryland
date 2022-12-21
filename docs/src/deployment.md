# Setting Up Deployment

Nedryland provides a set of convenience functionality for creating
deployments. Note that deployment is not actually done inside the
derivation, instead it generates a deploy script that can be run
outside of a nix context. This is because things like credentials and
network access make deployment inherently impure.

An example might look like

```nix
base.mkComponent {
  ...
  deployment = {
    terraform = base.deployment.mkTerraformDeployment {
      terraformPackage = package;
      inherit preDeployPhase postDeployPhase deployShellInputs;
    };
  };
}
```

Building a deployment script from this declaration can be done in two ways.
 1. The attribute `<componentName>.deployment.terraform`.
 2. The attribute `<componentName>.deploy` which is a combined target containing all deployments (which in this example is only one).

A deploy can now be performed by running the script in `bin/deploy` in
the resulting derivation (usually accessed by the `result`
symlink). Most deployments also comes with a deployment shell that is
typically used to interact with the deployed environment. To enter
this shell run `bin/shell` in the resulting derivation.

## Setting up project deployment targets

`mkProject` accepts extra targets and `deploy` is conventionally used
for project deployment targets and can be accessed through `deploy.<attribute>`.

All values in this set should be deployment derivations, or
combinations of them which can be created with the convenience
function `mkCombinedDeployment` available in `base`.

```nix
nedryland.mkProject {
  ...
  deploy = { mkCombinedDeployment }: {
    group = {
      comp1 = component1.deploy;
      comp2 = component2.deploy;
    }
    combined = mkCombinedDeployment "combined" {
      comp3 = component3.deploy;
      comp4 = component4.deploy;
    }
  }
}
```
 - `deploy.group.comp1` will create a deploy script for component1.
 - `deploy.group` will create two separate deploy script for component1 and component2.
 - `deploy.combined` will create one deploy script for component3 and component4.
 - `deploy.combined.comp3` will not work.

# Creating new deployment types

To aid in creating the deploy script and shell Nedryland provides the
function `base.deployment.mkDeployment`. This function takes one
mandatory argument.

`deployPhase`: This is the actual deploy script. This can either be
the inline deploy script or call an external utility. The environment
is similar to the shell one, but it is recreated outside of nix

Furthermore it accepts these optional arguments.

`preDeployPhase`: Script code to execute before the deploy phase and when
opening the shell. A typical usecase is to aquire credentials and set
up connection details.
`postDeployPhase`: Script code to execute after the
deploy phase. Used to cleaning up resources aquired during preDeployPhase.
`inputs`: A list of derivations that will be added to path for the
deployment script. These are typically dependencies you only need to
do the deployment of the artifact that aren't necessarily dependencies
of the artifact itself.
`shellInputs`: A list of derivations that will be added to path for
the shell.
`deployShell`: Is true by default, set it to false if you
do not want to have a deploy shell generated in your output.

Deployment will also pick up `preDeploy`, `postDeploy` and `preDeployShell` hooks.
