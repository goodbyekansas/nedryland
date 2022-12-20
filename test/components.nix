let
  componentFns = import ../component.nix { };
  project1 = {
    component1 = {
      name = "component-1";
      isNedrylandComponent = true;
    };
    component2 = {
      isNedrylandComponent = true;
    };
  };
  project2 = {
    component1 = {
      isNedrylandComponent = true;
      component1A = {
        isNedrylandComponent = true;
      };
      component1B = {
        isNedrylandComponent = true;
      };
    };
    component2 = {
      isNedrylandComponent = true;
      component2A = {
        isNedrylandComponent = true;
      };
      component2B = {
        isNedrylandComponent = true;
      };
    };
  };
  project3 = {
    component1 = {
      component1A = {
        isNedrylandComponent = true;
      };
      component1B = {
        isNedrylandComponent = true;
      };
    };
    component2 = {
      isNedrylandComponent = true;
      component2A = {
        isNedrylandComponent = true;
      };
      component2B = {
        isNedrylandComponent = true;
      };
    };
  };
  removeAccessPath = builtins.map (c: builtins.removeAttrs c [ "accessPath" ]);
in
assertMsg:
assert assertMsg
  (removeAccessPath
    (componentFns.collectComponentsRecursive project1)
  == (with project1; [ component1 component2 ]))
  "collectComponentsRecursive did not collect!";

assert assertMsg
  (removeAccessPath (componentFns.collectComponentsRecursive project2)
    == (with project2; [
    component1
    component1.component1A
    component1.component1B
    component2
    component2.component2A
    component2.component2B
  ]))
  "collectComponentsRecursive did not collect recursively!";

assert assertMsg
  (removeAccessPath (componentFns.collectComponentsRecursive project3) == (with project3; [ component2 component2.component2A component2.component2B ]))
  "collectComponentsRecursive did recurse into non-component (or other error)!";

assert assertMsg
  ((componentFns.mapComponentsRecursive (path: component: { inherit path; name = component.name or "no-name"; }) project1) == {
    component1 = { name = "component-1"; path = [ "component1" ]; };
    component2 = { name = "no-name"; path = [ "component2" ]; };
  })
  "mapComponentRecursive did not produce the expected result";
{ }
