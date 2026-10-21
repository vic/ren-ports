# element-web: the Element web client for json64.dev, at chat.json64.dev.
#
# Static files only: it logs in through MAS (mas.nix), which it finds from the
# homeserver's auth metadata and registers itself with dynamically. Its
# client_uri and redirect are both on chat.json64.dev, as MAS's registration
# policy requires. Route and CNP in element-web-route.nix.
{ ren, lib, ... }:
let
  elementConfig = cluster: {
    default_server_config."m.homeserver" = {
      base_url = "https://${ren.helpers.clusterDomainFor cluster "matrix"}";
      server_name = "json64.dev";
    };
    disable_custom_urls = true;
    disable_guests = true;
    brand = "Element";
    default_theme = "dark";
    room_directory.servers = [ "json64.dev" ];
    # Signed out, go straight to MAS, which forwards to kanidm (its only
    # provider). MAS's consent screen is the one prompt left.
    sso_redirect_options.immediate = true;
  };
in
{
  ren.aspects.k8s-communication-matrix-element-web = {
    service-domains = [ "chat" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "chat" ];

    k8s-manifests =
      {
        cluster,
        charts,
        images,
        ...
      }:
      {
        applications.element-web = {
          namespace = "matrix";

          helm.releases.element-web = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              defaultPodOptions.securityContext = {
                runAsNonRoot = true;
                runAsUser = 101; # the image's nginx user
                runAsGroup = 101;
              };
              controllers.main = {
                type = "deployment";
                replicas = 1;
                pod.annotations."checksum/config" = builtins.hashString "sha256" (
                  builtins.toJSON (elementConfig cluster)
                );
                containers.main = {
                  image = {
                    inherit (images."element-hq/element-web") repository digest;
                  };
                  # The image's nginx listens on ELEMENT_WEB_PORT; 80 needs root.
                  env.ELEMENT_WEB_PORT = "8080";
                  probes = lib.genAttrs [ "liveness" "readiness" ] (_: {
                    enabled = true;
                    custom = true;
                    spec.httpGet = {
                      path = "/version";
                      port = 8080;
                    };
                  });
                };
              };
              service.main = {
                controller = "main";
                ports.http.port = 8080;
              };
              persistence.config = {
                type = "configMap";
                name = "element-web-config";
                globalMounts = [
                  {
                    path = "/app/config.json";
                    subPath = "config.json";
                    readOnly = true;
                  }
                ];
              };
            };
          };

          resources.configMaps."element-web-config".data."config.json" = builtins.toJSON (elementConfig cluster);
        };
      };
  };
}
