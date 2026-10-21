# hindsight ingress policies, part 1 (metrics, CP). In-cluster egress (hindsight-pg, kube-dns) is
# already covered by the clusterwide allow-internal-egress policy (cilium.nix),
# so only the off-cluster paths and the ingress are enumerated here.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
  inherit (shared) port tcp;
  dataplane = {
    "app.kubernetes.io/name" = "hindsight";
  };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests.applications.hindsight.resources.ciliumNetworkPolicies = {
    # Declaring any ingress rule flips this pod to ingress default-deny.
    # Prometheus is the only legitimate caller in this wave; the gateway
    # is added when the route is.
    allow-metrics-ingress-hindsight.spec = {
      description = "Allow Prometheus to scrape hindsight (8888).";
      endpointSelector.matchLabels = dataplane;
      ingress = [
        {
          fromEndpoints = [
            {
              matchLabels = {
                "k8s:io.kubernetes.pod.namespace" = "monitoring";
                "app.kubernetes.io/name" = "prometheus";
              };
            }
          ];
          toPorts = tcp [ port ];
        }
      ];
    };

    # The control plane reaches the API from a POD address (172.20/16),
    # which the LAN rule below does not cover — without this the
    # ingress default-deny silently drops it.
    # Namespace-pinned: the app label alone would admit a pod carrying it
    # in any namespace.
    allow-cp-ingress-hindsight.spec = {
      description = "Allow the hindsight control plane to reach the dataplane API (8888).";
      endpointSelector.matchLabels = dataplane;
      ingress = [
        {
          fromEndpoints = [
            {
              matchLabels = {
                "k8s:io.kubernetes.pod.namespace" = "ai";
                "app.kubernetes.io/name" = "hindsight-cp";
              };
            }
          ];
          toPorts = tcp [ port ];
        }
      ];
    };
  };
}
