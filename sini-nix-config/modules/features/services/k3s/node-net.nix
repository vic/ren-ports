# K3s node networking: resolved DNSSEC, firewall, tailscale netfilter. Same aspect as node.nix.
{ ... }:
{
  ren.aspects.svc-k3s-node.nixos =
    { lib, ... }:
    {
      # DNSSEC off: resolved fails registry.k8s.io's redirect target us-west2-docker.pkg.dev
      # (CNAME to unsigned l.googleusercontent.com) with "failed-auxiliary", so containerd gets
      # `no such host` and sig-storage images ImagePullBackOff. Pods are unaffected.
      services.resolved.dnssec = "false";

      networking.firewall = {
        enable = lib.mkForce false;

        allowedTCPPorts = lib.flatten [
          179 # BGP
          6443 # Kubernetes API
          6444
          6081
          10250 # Kubelet metrics
          2379 # etcd
          2380 # etcd
          4240 # Cilium healthcheck
          4244 # Hubble API
          8080
          443
          9500 # Longhorn Manager
        ];

        allowedUDPPorts = [
          8472 # Cilium VXLAN
          4789 # Cilium VXLAN fallback
          51820 # WireGuard
        ];

        trustedInterfaces = [
          "lo"
          "cni+"
          "cilium+"
          "lxc+"
          "enp199s0f5"
          "enp199s0f6"
        ];

        extraCommands = ''
          iptables -A nixos-fw -p vrrp -j ACCEPT
        '';
      };

      # Stop tailscale managing netfilter on k3s nodes: its nftables mode writes raw-nft chains
      # into shared mangle/nat/filter tables, which Cilium's iptables-nft then refuses and crashes.
      # extraSetFlags (not extraUpFlags): autoconnect only runs `tailscale up` on first auth.
      # --accept-dns=false: MagicDNS search domain leaks into pods (ndots:5) and hijacks pod TLS
      # via the CF-proxied `*.ts.json64.dev` wildcard; k3s nodes must never inherit MagicDNS.
      services.tailscale.extraSetFlags = [
        "--netfilter-mode=off"
        "--accept-dns=false"
      ];
    };
}
