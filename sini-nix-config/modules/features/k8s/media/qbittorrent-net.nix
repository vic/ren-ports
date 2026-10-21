# qBittorrent CNPs: gateway-ingress (:8080), VPN egress, *arr ingress.
# INVARIANT: the ONLY world egress is UDP/51820 (WireGuard) + cluster DNS. Do NOT add a world-TCP
# egress policy to this pod: it would punch a cleartext hole through the kill-switch.
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { ... }:
    {
      applications.qbittorrent.resources.ciliumNetworkPolicies = {
        # Routed-app baseline: Envoy Gateway proxies (ns "gateways") -> :8080.
        allow-gateway-ingress-qbittorrent.spec = {
          description = "Allow Envoy Gateway proxies to reach qbittorrent.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "qbittorrent";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8080";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        # gluetun's WireGuard handshake/data. Endpoint IP/port are secret (a CNP can't read them),
        # so allow the standard ProtonVPN WireGuard port (UDP 51820) to all of world.
        allow-vpn-egress-qbittorrent.spec = {
          description = "Allow the gluetun sidecar to reach the ProtonVPN WireGuard endpoint (UDP 51820).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "qbittorrent";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "51820";
                      protocol = "UDP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        # In-namespace *arr API callers + unpackerr reach the WebUI on 8080 (download-client
        # registration + queue management).
        allow-arr-ingress-qbittorrent.spec = {
          description = "Allow the *arrs and unpackerr to reach qBittorrent's WebUI API (8080).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "qbittorrent";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."app.kubernetes.io/name" = "sonarr"; }
                { matchLabels."app.kubernetes.io/name" = "radarr"; }
                { matchLabels."app.kubernetes.io/name" = "lidarr"; }
                { matchLabels."app.kubernetes.io/name" = "whisparr"; }
                { matchLabels."app.kubernetes.io/name" = "prowlarr"; }
                { matchLabels."app.kubernetes.io/name" = "unpackerr"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8080";
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
