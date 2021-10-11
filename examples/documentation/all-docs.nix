{ base, components, lib, tree, linkFarm }:
let
  site = linkFarm
    "all-docs"
    (lib.flatten (lib.mapAttrsToList
      (n: v: lib.mapAttrsToList
        (n': path: {
          inherit path;
          name = "${n}-${n'}";
        })
        v.docs)
      components))
  ;
in
base.deployment.mkDeployment {
  name = "project-documentation";
  inputs = [ tree ];
  deployPhase = ''
    echo "Here we would upload ${site}"
    echo "Here we would make a start page that links to these html files"
    tree '${site}' -l --noreport -P "index.html"
    echo "and upload somewhere"
  '';
}
