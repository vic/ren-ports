# searxng network policies. EGRESS: DNS through Cilium's DNS proxy (toFQDNs
# learns IPs only from lookups that pass it, as in genie-eval-net.nix), then the
# engine hosts on 443.
_:
let
  inherit (import ./_searxng-shared.nix) name port pod tcp;
  inherit (import ./_searxng-settings.nix) engineHosts;
  ingressOn = peer: peer // { toPorts = [ { ports = [ (tcp port) ]; } ]; };
in
{
  ren.aspects.k8s-ai-searxng.k8s-manifests = { ... }: {
    applications.${name}.resources.ciliumNetworkPolicies = {
      "${name}-ingress".spec = {
        description = "searxng: the gateway, genie tier 1 and private-LAN clients, on ${toString port} only.";
        endpointSelector.matchLabels = pod;
        ingress = [
          (ingressOn {
            fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
          })
          (ingressOn {
            fromEndpoints = [
              {
                matchLabels = {
                  "k8s:io.kubernetes.pod.namespace" = "genie";
                  "k8s:io.cilium.k8s.policy.serviceaccount" = "genie-tier1";
                };
              }
            ];
          })
          # Off-cluster callers over the internal LoadBalancer: the whole
          # private 10/8, as allow-lan-ingress-hindsight reasons (portable;
          # covers the caller's real IP under externalTrafficPolicy=Local
          # and any node SNAT; the LB address is not internet-routable).
          (ingressOn { fromCIDR = [ "10.0.0.0/8" ]; })
        ];
      };

      "${name}-egress".spec = {
        description = "searxng: DNS, then the engine hosts on 443.";
        endpointSelector.matchLabels = pod;
        egress = [
          {
            toEndpoints = [
              {
                # coredns.nix's own selector: the chart labels its pods
                # k8s-app=coredns; only the Service carries kube-dns.
                matchLabels = {
                  "k8s:io.kubernetes.pod.namespace" = "kube-system";
                  "app.kubernetes.io/name" = "coredns";
                };
              }
            ];
            toPorts = [
              {
                ports = [
                  {
                    port = "53";
                    protocol = "UDP";
                  }
                  (tcp 53)
                ];
                rules.dns = [ { matchPattern = "*"; } ];
              }
            ];
          }
          {
            toFQDNs = map (matchName: { inherit matchName; }) engineHosts;
            toPorts = [ { ports = [ (tcp 443) ]; } ];
          }
        ];
      };
    };
  };
}
