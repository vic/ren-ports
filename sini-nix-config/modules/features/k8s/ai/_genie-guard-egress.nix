# The clusterwide egress policy spec granting genie-guard its hubs' federation ports.
targets:
let
  inherit (import ./_genie-guard-shared.nix) namespace name;
in
{
  description = "Allow ${namespace}/${name} to its xmsg hubs' federation ports.";
  endpointSelector.matchExpressions = [
    {
      key = "k8s:io.kubernetes.pod.namespace";
      operator = "In";
      values = [ namespace ];
    }
    {
      key = "k8s:io.cilium.k8s.policy.serviceaccount";
      operator = "In";
      values = [ name ];
    }
  ];
  egress = map (h: {
    toCIDR = [ "${h.ip}/32" ];
    toPorts = [
      {
        ports = [
          {
            port = toString h.port;
            protocol = "TCP";
          }
        ];
      }
    ];
  }) targets;
}
