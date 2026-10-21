# Static status dashboard for the gen ecosystem (gen-status.json64.dev).
{ ren, ... }:
let
  serviceDomains = [ "gen-status" ];
in
{
  ren.aspects.svc-web-gen-status = {
    includes = with ren.aspects; [ svc-networking-nginx ];

    nixos =
      {
        environment,
        host,
        ...
      }:
      let
        domain = ren.helpers.domainFor environment "gen-status";
        docRoot = "/var/lib/gen-status";
      in
      {
        services.nginx.virtualHosts = {
          "${domain}" = {
            forceSSL = true;
            useACMEHost = environment.domain;
            locations."/" = {
              root = docRoot;
              extraConfig = ''
                try_files $uri $uri/index.html $uri.html =404;
                etag on;
              '';
            };
            locations."/data/" = {
              root = docRoot;
              extraConfig = ''
                add_header Cache-Control "public, max-age=60, must-revalidate";
                gzip_static on;
              '';
            };
          };
        };
      };

    service-domains = serviceDomains;
    served-domains = { environment, host, ... }: ren.helpers.servedDomains environment host serviceDomains;

    persist = {
      directories = [
        {
          directory = "/var/lib/gen-status";
          user = "sini";
          mode = "0755";
        }
      ];
    };
  };
}
