# Media network-policy extras. unpackerr takes NO inbound: enableDefaultDeny.ingress (Cilium >=1.14) engages
# ingress default-deny with no bogus allow (an `ingress: [{}]` rule would mean allow-all). The agent-side rule
# sanitizer rejects a spec whose only section is an empty list (pods then ran with NO ingress enforcement), so
# one real allow is added: the local host (kubelet probes, exempt by default anyway).
# media-pg internal mesh: CNPG instance pods take ingress from in-namespace app pods (5432), peer instances
# (replication 5432 + instance manager 8000), the cnpg-system operator (8000) and prometheus (9187). The
# instance->apiserver egress is in media-pg-monitor.nix.
{ ... }:
{
  ren.aspects.k8s-media-network-policy.k8s-manifests =
    { ... }:
    {
      applications.media-network-policy.resources.ciliumNetworkPolicies = {
        deny-media-ingress-unpackerr.spec = {
          description = "Default-deny all ingress to unpackerr (no inbound callers).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "unpackerr";
          enableDefaultDeny.ingress = true;
          ingress = [ { fromEntities = [ "host" ]; } ];
        };

        allow-media-pg-internal.spec = {
          description = "media-pg ingress: app clients (5432), peer replication (5432/8000), CNPG operator status (8000).";
          endpointSelector.matchLabels."cnpg.io/cluster" = "media-pg";
          ingress = [
            # in-namespace application clients -> postgres 5432
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "media"; } ];
              toPorts = [ { ports = [ { port = "5432"; protocol = "TCP"; } ]; } ];
            }
            # peer instances -> postgres/replication 5432 and instance-manager 8000
            {
              fromEndpoints = [ { matchLabels."cnpg.io/cluster" = "media-pg"; } ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "5432";
                      protocol = "TCP";
                    }
                    {
                      port = "8000";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
            # CNPG operator (cnpg-system) -> instance-manager status 8000
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "cnpg-system"; } ];
              toPorts = [ { ports = [ { port = "8000"; protocol = "TCP"; } ]; } ];
            }
            # prometheus (monitoring) -> instance metrics exporter 9187
            {
              fromEndpoints = [
                {
                  matchLabels = {
                    "k8s:io.kubernetes.pod.namespace" = "monitoring";
                    "app.kubernetes.io/name" = "prometheus";
                  };
                }
              ];
              toPorts = [ { ports = [ { port = "9187"; protocol = "TCP"; } ]; } ];
            }
          ];
        };
      };
    };
}
