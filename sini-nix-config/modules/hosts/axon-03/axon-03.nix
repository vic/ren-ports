{ ren, ... }:
{
  ren.host.axon-03 = {
    system = ren.system.x86_64-linux;
    channel = ren.channel.nixos-unstable;
    environment = ren.environment.prod;
    system-owner = ren.user.sini;
    system-access-groups = [ ren.group.server-access ];

    networking.interfaces = {
      enp2s0 = {
        ipv4 = [ "10.10.10.4/16" ];
        ipv6 = [ "fe80::dc50:e5ff:feac:7353" ];
        # Deterministic IPv6 egress: a single GUA from DHCPv6 only — no SLAAC
        # autoconf, no rotating privacy temps — so the node sources from, and
        # Cilium masquerades pods to, the same warm address (return traffic to
        # the SNAT source no longer goes stale).
        privacyExtensions = "no";
        acceptRAAutonomousPrefix = false;
      };
      enp199s0f5 = { };
      enp199s0f6 = { };
    };

    svc-bgp.localAsn = 65001;
    svc-bgp-cilium-bgp.localAsn = 65010;
    svc-k3s.clusterName = "axon";
    svc-networking-thunderbolt-mesh-of = {
      interfaces = [
        "enp199s0f5"
        "enp199s0f6"
      ];
      loopback.ipv4 = "172.16.255.3/32";
      # Fabric v6 loopbacks: fdfd:cafe:0:ff::/64 reserved for the mesh
      # (pods 0:1::/96, services 0:8001::/112 — see clusters/axon.nix)
      loopback.ipv6 = "fdfd:cafe:0:ff::3/128";
      nsap = "49.0000.0000.0003.00";
    };
    disk-zfs-disk-single.device_id = "/dev/disk/by-id/nvme-KINGSTON_OM8PGP41024Q-A0_50026B738300CCCC";
    disk-xfs-disk-longhorn.device_id = "/dev/disk/by-id/nvme-Force_MP600_1925823000012856500E";
    impermanence = {
      wipeRootOnBoot = true;
      wipeHomeOnBoot = true;
    };
  };

  ren.aspects.axon-03 = {
    at = ren.host.axon-03;
    includes = with ren.aspects; [
      default
      boot-network-initrd
      disk-zfs-disk-single
      disk-xfs-disk-longhorn
      server
      unlock
      nix-builder
      svc-bgp-spoke
      svc-bgp-cilium-bgp
      svc-k3s
      hardware-cpu-amd
      hardware-gpu-amd
      svc-networking-thunderbolt-mesh-of
    ];
    nixos.facter.reportPath = ../../../hosts/axon-03/facter.json;
  };
}
