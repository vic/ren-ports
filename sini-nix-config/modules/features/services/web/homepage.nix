{ ren, ... }:
let
  serviceDomains = [ "homepage" ];
in
{
  ren.aspects.svc-web-homepage = {
    includes = with ren.aspects; [
      svc-networking-nginx
      svc-security-oauth2-proxy
    ];

    nixos =
      {
        environment,
        host,
        ...
      }:
      let
        domain = ren.helpers.domainFor environment "homepage";
      in
      {
        services = {
          homepage-dashboard = {
            enable = true;
            listenPort = 8082;

            allowedHosts = "*";

            services = [
              {
                "Self-hosted services" = [
                  {
                    "Blog" = {
                      description = "Blog";
                      href = "http://google.com/";
                      siteMonitor = "http://google.com/";
                      icon = "sonarr.png";
                    };
                  }
                ];
              }
              {
                "My Second Group" = [
                  {
                    "My Second Service" = {
                      description = "Homepage is the best";
                      href = "http://localhost/";
                    };
                  }
                ];
              }
            ];

            settings = {
              title = "hello world";
            };

            bookmarks = [
              {
                Developer = [
                  {
                    Github = [
                      {
                        abbr = "GH";
                        href = "https://github.com/";
                      }
                    ];
                  }
                ];
              }
              {
                Entertainment = [
                  {
                    YouTube = [
                      {
                        abbr = "YT";
                        href = "https://youtube.com/";
                      }
                    ];
                  }
                ];
              }
            ];
          };

          oauth2-proxy.nginx.virtualHosts = {
            "${domain}" = { };
          };

          nginx.virtualHosts = {
            "${domain}" = {
              forceSSL = true;
              useACMEHost = environment.domain;
              locations."/" = {
                proxyPass = "http://127.0.0.1:8082";
                proxyWebsockets = true;
              };
            };
          };
        };
      };

    service-domains = serviceDomains;
    served-domains = { environment, host, ... }: ren.helpers.servedDomains environment host serviceDomains;
  };
}
