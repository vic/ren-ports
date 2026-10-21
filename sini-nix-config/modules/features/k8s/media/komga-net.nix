# Komga CNP: gateway-ingress only (no internet egress, no postgres).
{ ... }:
{
  ren.aspects.k8s-media-komga.k8s-manifests =
    { ... }:
    {
      applications.komga.resources.ciliumNetworkPolicies.allow-gateway-ingress-komga.spec = {
        description = "Allow Envoy Gateway proxies to reach komga.";
        endpointSelector.matchLabels."app.kubernetes.io/name" = "komga";
        ingress = [
          {
            fromEndpoints = [
              { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
            ];
            toPorts = [
              {
                ports = [
                  {
                    port = "25600";
                    protocol = "TCP";
                  }
                ];
              }
            ];
          }
        ];
      };
    };
}
