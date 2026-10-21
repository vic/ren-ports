# K3s server flags and services.k3s. HA/keepalived half is ha.nix (same aspect).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.svc-k3s.nixos =
    { k3s-nodes, config, host, environment, ... }:
    let
      cluster = ren.helpers.clusterOf host;
      vip = ren.helpers.getAssignment cluster "kube-apiserver-vip";
      v4 = builtins.head (ren.helpers.ipv4Of host);
      v6 = builtins.head (ren.helpers.ipv6Of host);

      # Same-environment scoping guaranteed by the k3s-nodes channel
      clusterNodes = lib.filter (n: n.clusterName == host.svc-k3s.clusterName) k3s-nodes;
      sortedNodes = builtins.sort (a: b: a.hostname < b.hostname) clusterNodes;

      # Bootstrap when only one node is declared (initial cluster formation)
      shouldInit = builtins.length sortedNodes == 1;
      otherNodes = lib.filter (node: node.hostname != host.name) sortedNodes;
      masterIP = if shouldInit then vip else (lib.head otherNodes).ip;

      # TLS SANs: VIP + all peer node IPs + hostnames + tailscale names +
      # fabric loopbacks (etcd peer traffic is sourced from these over the mesh)
      peerTlsSans = lib.flatten (
        map (
          node:
          [
            "--tls-san=${node.ip}"
            "--tls-san=${node.hostname}"
            "--tls-san=${node.hostname}.ts.${environment.domain}"
          ]
          ++ lib.optional (node.fabricLoopback or null != null) "--tls-san=${node.fabricLoopback}"
        ) sortedNodes
      );

      generalFlagList = [
        "--snapshotter=overlayfs"
        # Bare path, NOT unix://...: k3s forwards this value to the kubelet's
        # legacy cadvisor --containerd flag, which dials it verbatim — with
        # a scheme the dial fails ("dial unix unix:///..."), cadvisor falls
        # back to its systemd factory, and per-container + pod-network
        # metrics silently vanish (only pod-level cgroup series remain,
        # so every kps resource dashboard reads empty). The kubelet
        # normalizes the bare path for CRI itself.
        "--container-runtime-endpoint=/run/containerd/containerd.sock"

        "--node-ip=${v4},${v6}"
        "--node-external-ip=${v4},${v6}"
        "--node-name=${config.networking.hostName}"
        "--node-label=node.longhorn.io/create-default-disk=true"
        "--node-label=node.kubernetes.io/amd-gpu=true"
      ]
      ++ lib.optional host.svc-k3s.gvisor "--node-label=node.kubernetes.io/gvisor=true"
      ++ [
        "--node-label \"k3s-upgrade=false\""
        "--kubelet-arg=register-with-taints=node.cilium.io/agent-not-ready:NoExecute"
      ];

      serverFlagList = import ./_server-flags.nix {
        inherit ren config environment cluster v4 vip peerTlsSans;
      };
    in
    lib.mkIf (cluster != null) {
      services.k3s = {
        clusterInit = shouldInit;
        enable = true;
        role = "server";
        tokenFile = config.age.secrets.kubernetes-cluster-token.path;
        gracefulNodeShutdown.enable = true;
        extraFlags = lib.mkForce (lib.concatStringsSep " " (generalFlagList ++ serverFlagList));
      }
      // lib.optionalAttrs (!shouldInit) { serverAddr = "https://${masterIP}:6443"; };
    };
}
