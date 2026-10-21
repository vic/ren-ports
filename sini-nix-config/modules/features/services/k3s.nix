# K3s server aspect: full server-mode k3s with HA (keepalived VRRP), Cilium CNI (flannel disabled),
# OIDC via Kanidm, etcd snapshots, and bootstrap services (Cilium -> CoreDNS -> SOPS -> ArgoCD).
# Emits k3s-nodes channel; consumes collected nodes for peer discovery, bootstrap ordering,
# keepalived and TLS SANs.
# Halves: k3s/server.nix (flags + k3s), k3s/ha.nix (keepalived, longhorn bits),
# k3s/registries.nix, k3s/state.nix (secrets, persist), k3s/bootstrap.nix, k3s/containerd.nix.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-k3s = ren.lib.opt (lib.types.submodule {
    options = {
      clusterName = lib.mkOption {
        type = lib.types.str;
        default = "axon";
        description = "Name of the cluster entry this host belongs to";
      };
      gvisor = lib.mkEnableOption ''
        the gVisor (runsc) containerd runtime handler on this node. Labels the
        node node.kubernetes.io/gvisor=true, which the `gvisor` RuntimeClass
        (k8s-hardware-gvisor) schedules onto'';
    };
  }) { };

  ren.aspects.svc-k3s = {
    includes = with ren.aspects; [
      svc-k3s-containerd
      svc-k3s-node
      svc-k3s-bootstrap
      svc-k3s-node-lifecycle
    ];

    # The embedded etcd's metrics, scraped by the ingester. (k3s itself has no
    # unauthenticated metrics port: 10249 is kube-proxy's, which cilium replaces.)
    prometheus-targets =
      { environment, host, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        inherit environment;
        exporters = [
          {
            job = "etcd";
            port = 2381;
          }
        ];
      };

    # Emit node info for peer discovery
    k3s-nodes =
      { environment, host, is, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        ipv6 = builtins.head (ren.helpers.ipv6Of host);
        inherit environment;
        clusterName = host.svc-k3s.clusterName;
        # BGP and cilium-bgp settings needed by cilium-bgp-resources
        bgpLocalAsn = if is ren.aspects.svc-bgp host then host.svc-bgp.localAsn else null;
        ciliumBgpLocalAsn = if is ren.aspects.svc-bgp-cilium-bgp host then host.svc-bgp-cilium-bgp.localAsn else null;
        # OpenFabric loopback (if on the thunderbolt mesh). Inter-node etcd/k3s traffic to peer
        # mgmt IPs is routed over the fabric and sourced from this loopback, so it must be a TLS
        # SAN or peer-cert checks reject it.
        fabricLoopback =
          if (host.svc-networking-thunderbolt-mesh-of or { }).loopback or null != null then
            builtins.head (lib.splitString "/" host.svc-networking-thunderbolt-mesh-of.loopback.ipv4)
          else
            null;
      };
  };
}
