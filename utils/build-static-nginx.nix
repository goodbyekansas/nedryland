pkgs: { name, locations, content, tag ? "head"}:
let
  nginxConf = pkgs.writeText "nginx.conf" ''
      user nginx nginx;
      daemon off;
      error_log /dev/stdout info;
      pid /dev/null;
      events {}
      http {
        access_log /dev/stdout;
        include ${pkgs.mailcap}/etc/nginx/mime.types;
        server {
          listen 80;
          index index.html;
          ${builtins.concatStringsSep "\n" (pkgs.lib.reverseList (pkgs.lib.mapAttrsToList (location: attrs: ''
          location ${location} {
            ${if attrs ? root then "root ${attrs.root};" else ""}
            ${if attrs ? alias then "alias ${attrs.alias};" else ""}
            ${if attrs ? redirectTo then "return 301 ${attrs.redirectTo};" else ""}
            ${if (attrs.redirectToIndex or false) then ''
            try_files $uri $uri/ /index.html;
            '' else ""}
            autoindex ${if (attrs.directoryListing or false) then "on" else "off"};
          }
          '') locations))}
        }
      }
  '';
in
  pkgs.dockerTools.buildImage {
    inherit tag;
    name = "${name}";
    created = "now";

    runAsRoot = ''
      #!${pkgs.stdenv.shell}
      ${pkgs.dockerTools.shadowSetup}
      groupadd --system nginx
      useradd --system --gid nginx nginx
    '';

    contents = [ pkgs.nginx pkgs.mailcap ] ++ content;
    config = {
      Cmd = ["nginx" "-c" nginxConf];
    };
  }

