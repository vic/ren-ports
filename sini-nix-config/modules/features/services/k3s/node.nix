# K3s node host setup, kernel modules, sysctls and tooling independent of cluster membership.
# Firewall/resolved/tailscale half is in node-net.nix (same aspect).
{ ... }:
{
  ren.aspects.svc-k3s-node.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.k3s
        pkgs.k9s
        pkgs.kubectl
        pkgs.istioctl
        pkgs.kubernetes-helm
        pkgs.cilium-cli

        pkgs.clusterctl
        pkgs.nerdctl

        pkgs.skopeo
        pkgs.go-containerregistry
        pkgs.dive

        pkgs.openiscsi
        pkgs.nfs-utils

        pkgs.util-linux
        pkgs.parted
        pkgs.gptfdisk
        pkgs.lvm2

        # Host iptables/nftables on PATH. With the firewall disabled NixOS installs no iptables
        # wrapper, so k3s falls back to bundled binaries and leaves tables on a backend Cilium's
        # nft iptables-wrapper rejects ("table `mangle' is incompatible, use 'nft' tool").
        # Host iptables-nft + nft keeps k3s, kubelet and Cilium on one nft backend.
        pkgs.iptables
        pkgs.nftables
      ];

      boot = {
        kernelModules = [
          # Filesystem
          "ceph"
          "rbd"
          "nfs"
          "overlay"
          # Networking / eBPF
          "bpf"
          "ip_tables"
          "br_netfilter"
          "nft-expr-counter"
          "iptable_nat"
          "iptable_filter"
          "nft_counter"
          "ip6_tables"
          "ip6table_mangle"
          "ip6table_raw"
          "ip6table_filter"
          "ip_conntrack"
          "ip_vs"
          "ip_vs_rr"
          "ip_vs_wrr"
          "ip_vs_sh"
          "iscsi_tcp"
        ];

        kernel.sysctl = {
          "net.bridge.bridge-nf-call-iptables" = 1;
          "net.bridge.bridge-nf-call-ip6tables" = 1;
          "net.core.bpf_jit_enable" = 1;
          "net.core.bpf_jit_harden" = 0;
        };

        blacklistedKernelModules = [ "nbd" ];
      };
    };
}
