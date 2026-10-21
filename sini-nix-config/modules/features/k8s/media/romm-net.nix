# RomM CNPs: gateway ingress, media-pg egress, internet egress (kanidm OIDC + metadata providers),
# valkey egress/ingress (valkey chart labels pods instance=romm-redis, name=valkey).
{ ... }:
{
  ren.aspects.k8s-media-romm.k8s-manifests =
    { ... }:
    {
      applications.romm.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-romm.spec = {
          description = "Allow Envoy Gateway proxies to reach romm.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "romm";
          ingress = [
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
              toPorts = [ { ports = [ { port = "8080"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        allow-postgres-egress-romm.spec = {
          description = "Allow romm to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "romm";
          egress = [
            {
              toEndpoints = [ { matchLabels."cnpg.io/cluster" = "media-pg"; } ];
              toPorts = [ { ports = [ { port = "5432"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        allow-internet-egress-romm.spec = {
          description = "Allow romm to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "romm";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    { port = "80"; protocol = "TCP"; }
                    { port = "443"; protocol = "TCP"; }
                  ];
                }
              ];
            }
          ];
        };

        allow-redis-egress-romm.spec = {
          description = "Allow romm to reach its valkey (romm-redis).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "romm";
          egress = [
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/instance" = "romm-redis"; } ];
              toPorts = [ { ports = [ { port = "6379"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        allow-romm-ingress-redis.spec = {
          description = "Allow romm to reach the romm-redis valkey.";
          endpointSelector.matchLabels."app.kubernetes.io/instance" = "romm-redis";
          ingress = [
            {
              fromEndpoints = [ { matchLabels."app.kubernetes.io/name" = "romm"; } ];
              toPorts = [ { ports = [ { port = "6379"; protocol = "TCP"; } ]; } ];
            }
          ];
        };
      };
    };
}
