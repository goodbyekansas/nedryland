# Setting Up Deployment

Nedryland provides a set of convenience functionality for creating deployments. However, it does not
contain any integration logic and therefore will not actually do any deployment. That logic is
provided by you in the project setup and more precisely in the call to `project.mkGrid`.

An example might look like

```nix
deploy = rec {
  functions = firm.getFunctionDeployments {
    inherit components;
  };

  local = [
    functions
  ];

  prod = [
    (
      firm.getFunctionDeployments {
        inherit components;
        endpoint = "tcp://a.production.registry";
        port = 1337;
      }
    )
  ];
};
```

This example defines three deploy targets: `functions`, `local`, and `prod`. The targets are normal
Nix targets and can be invoked with `nix-build -A functions` or `nix-build -A local` or `nix-build
-A prod`.
