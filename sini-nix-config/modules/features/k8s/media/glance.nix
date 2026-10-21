# Glance: at-a-glance media dashboard. Stateless single binary, config is a ConfigMap
# (glance-config.nix), so no config PVC. Routed + OIDC-protected on the gateway (clientID "glance").
# CNPs in glance-net.nix, route/OIDC in glance-route.nix.
# Image: rolling `latest`, digest-pinned in images/glanceapp/glance.
{ ren, ... }:
{
  ren.aspects.k8s-media-glance = {
    service-domains = [ "glance" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "glance" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.glance-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/glance-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "glance";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.glance = {
          namespace = "media";

          helm.releases.glance = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                containers.main = {
                  image = {
                    inherit (images."glanceapp/glance") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 8080;
              };
            };
          };
        };
      };
  };
}
