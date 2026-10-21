# kube-prometheus-stack CiliumNetworkPolicies. Same aspect as prometheus.nix.
# The cluster default-denies egress to anything that isn't a cilium-managed
# endpoint; the apiserver and kubelets are host-network and need explicit entity rules.
{ lib, ... }:
let
  toPorts = ports: [
    {
      ports = map (port: {
        inherit port;
        protocol = "TCP";
      }) ports;
    }
  ];
  apiserver = {
    toEntities = [ "kube-apiserver" ];
    toPorts = toPorts [ "6443" ];
  };
in
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests =
    { cluster, prometheus-targets, ... }:
    let
      outsideAlertmanagers = lib.concatMap (
        t: map (e: "${t.ip}:${toString e.port}") (lib.filter (e: e.job == "alertmanager") t.exporters)
      ) (lib.filter (t: t.environment.name == cluster.environment.name) prometheus-targets);
    in
    {
      applications.kube-prometheus-stack.resources.ciliumNetworkPolicies = {
        allow-operator-kube-apiserver-egress.spec = {
          endpointSelector.matchLabels.app = "kube-prometheus-stack-operator";
          egress = [ apiserver ];
        };

        allow-prometheus-scrape-egress.spec = {
          endpointSelector.matchLabels."app.kubernetes.io/name" = "prometheus";
          egress = [
            apiserver
            # Host-network scrape targets on every node: kubelet
            # (10250), cilium agent (9962), cilium operator (9963),
            # hubble metrics (9965).
            {
              toEntities = [
                "host"
                "remote-node"
              ];
              toPorts = toPorts [
                "10250"
                "9962"
                "9963"
                "9965"
              ];
            }
          ]
          # The Watchdog push to the outside Alertmanager.
          ++ map (target: {
            toCIDR = [ "${lib.head (lib.splitString ":" target)}/32" ];
            toPorts = toPorts [ (lib.last (lib.splitString ":" target)) ];
          }) outsideAlertmanagers;
        };

        allow-kube-state-metrics-kube-apiserver-egress.spec = {
          endpointSelector.matchLabels."app.kubernetes.io/name" = "kube-state-metrics";
          egress = [ apiserver ];
        };
      };
    };
}
