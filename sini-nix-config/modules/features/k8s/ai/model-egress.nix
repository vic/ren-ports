# model-egress: model endpoints on cortex-cuda, reachable only from allow-listed
# service accounts (federation plan 6.7). One CiliumClusterwideNetworkPolicy per
# (namespace, service account) pair; Cilium sets both labels from the pod spec.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
  pairT = t.submodule {
    options = {
      namespace = opt t.str null;
      serviceAccount = opt t.str null;
    };
  };
in
{
  # cortex-cuda's address and model ports, stated here (host-scoped config is
  # not readable from cluster scope). Sources: ninfer `port`, hyperqwen `port`.
  ren.kinds.cluster.k8s-ai-model-egress = opt (t.submodule {
    options = {
      cidr = opt t.str "10.9.2.2/32";
      ports = opt (t.listOf t.port) [
        8081 # ninfer
        18020 # hyperqwen
      ];
      allow = opt (t.listOf pairT) [
        {
          namespace = "genie";
          serviceAccount = "genie-guard";
        }
        {
          namespace = "genie";
          serviceAccount = "genie-tier1";
        }
      ];
    };
  }) { };

  ren.aspects.k8s-ai-model-egress.k8s-manifests =
    { cluster, ... }:
    let
      inherit (cluster.k8s-ai-model-egress) cidr ports allow;
    in
    {
      applications.model-egress = {
        namespace = "kube-system";

        resources.ciliumClusterwideNetworkPolicies = lib.listToAttrs (
          map (
            a:
            lib.nameValuePair "allow-model-egress-${a.namespace}-${a.serviceAccount}" {
              spec = {
                description = "Allow ${a.namespace}/${a.serviceAccount} to the cortex-cuda model ports.";
                endpointSelector.matchExpressions = [
                  {
                    key = "k8s:io.kubernetes.pod.namespace";
                    operator = "In";
                    values = [ a.namespace ];
                  }
                  {
                    key = "k8s:io.cilium.k8s.policy.serviceaccount";
                    operator = "In";
                    values = [ a.serviceAccount ];
                  }
                ];
                egress = [
                  {
                    toCIDR = [ cidr ];
                    toPorts = [
                      {
                        ports = map (port: {
                          port = toString port;
                          protocol = "TCP";
                        }) ports;
                      }
                    ];
                  }
                ];
              };
            }
          ) allow
        );
      };
    };
}
