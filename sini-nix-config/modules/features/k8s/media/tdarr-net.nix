# Tdarr CNPs: gateway-ingress (8265), node-worker ingress (8266), internet-egress (plugin repo fetch).
{ ... }:
{
  ren.aspects.k8s-media-tdarr.k8s-manifests =
    { ... }:
    {
      applications.tdarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-tdarr.spec = {
          description = "Allow Envoy Gateway proxies to reach tdarr's webUI.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8265";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        # Node-worker control channel: the gateway-ingress policy above flips the pod to default-deny
        # ingress, so the tdarr-node workers (same media namespace) need an explicit ingress to 8266
        # or they cannot register with the server.
        allow-nodeconn-ingress-tdarr.spec = {
          description = "Allow tdarr-node workers to reach the tdarr server's node port (8266).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."app.kubernetes.io/name" = "tdarr-node"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8266";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        # World egress (80/443): the server fetches its plugin repo (github) on boot to populate the
        # plugins folder. Without it the "Updating plugins" step times out (AxiosError 15000ms),
        # leaving the plugins incomplete, e.g. hardwareUtils.test.js missing, which fails the
        # FFmpeg-encoder enumeration on both server and nodes (nodes inherit the plugin set from the
        # server, so only the server needs egress).
        allow-internet-egress-tdarr.spec = {
          description = "Allow tdarr's server to fetch its plugin repo from the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr";
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
}
