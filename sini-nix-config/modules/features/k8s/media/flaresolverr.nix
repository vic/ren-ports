# FlareSolverr: Cloudflare/JS challenge solver for the indexers. Stateless, route-less, OIDC-less;
# reached in-cluster by Prowlarr. Needs world egress on 80/443.
{ ... }:
{
  ren.aspects.k8s-media-flaresolverr = {
    service-domains = [ ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.flaresolverr = {
          namespace = "media";

          helm.releases.flaresolverr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                containers.main = {
                  image = {
                    inherit (images."flaresolverr/flaresolverr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    LOG_LEVEL = "info";
                  };
                  envFrom = [ ];
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 8191;
              };
            };
          };

          resources.ciliumNetworkPolicies.allow-internet-egress-flaresolverr.spec = {
            description = "Allow flaresolverr to reach the public internet.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "flaresolverr";
            egress = [
              {
                toEntities = [ "world" ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "80";
                        protocol = "TCP";
                      }
                      {
                        port = "443";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
  };
}
