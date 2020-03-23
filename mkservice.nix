base: { name, package, deployment }:
base.mkComponent { inherit package deployment; }
