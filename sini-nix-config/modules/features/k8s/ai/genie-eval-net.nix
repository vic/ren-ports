# genie-eval egress: DNS, plus the fetch hosts by name (toFQDNs, 443 only). The
# DNS rule carries an L7 `dns` section because toFQDNs only learns IPs from
# lookups that pass Cilium's DNS proxy. In-cluster traffic is denied too, which
# needs the cluster-wide `allow-internal-egress` (network/cilium) to exclude this
# namespace: Cilium policies only add allows, so a CNP here cannot take that
# grant away.
#
# INGRESS: none. `enableDefaultDeny.ingress` engages ingress default-deny with
# no allow rule; the agent sanitizer accepts it because the egress section is
# non-empty (see media/network-policy.nix on the empty-only-section refusal).
_:
let
  fetchHosts = [
    "github.com"
    "codeload.github.com"
    "api.github.com"
    "channels.nixos.org"
    "releases.nixos.org"
    "tarballs.nixos.org"
  ];
in
{
  ren.aspects.k8s-ai-genie-eval.k8s-manifests = { ... }: {
    applications.genie-eval.resources.ciliumNetworkPolicies.genie-eval-egress.spec = {
      description = "Eval pods: DNS and the Nix fetch hosts only; no ingress, nothing in-cluster.";
      endpointSelector = { };
      enableDefaultDeny.ingress = true;
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
                {
                  port = "53";
                  protocol = "TCP";
                }
              ];
              rules.dns = [ { matchPattern = "*"; } ];
            }
          ];
        }
        {
          toFQDNs = map (matchName: { inherit matchName; }) fetchHosts;
          toPorts = [
            {
              ports = [
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
}
