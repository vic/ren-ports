{ ren, ... }:
let
  serviceDomains = [ "den-docs-mirror" ];
in
{
  ren.aspects.svc-web-den-docs-mirror = {
    includes = with ren.aspects; [ svc-networking-nginx ];

    nixos =
      {
        environment,
        host,
        ...
      }:
      let
        domain = ren.helpers.domainFor environment "den-docs-mirror";
        docRoot = "/var/lib/den-docs";
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
          directory = "/var/lib/den-docs";
          user = "sini";
          mode = "0755";
        }
      ];
    };
  };
}
