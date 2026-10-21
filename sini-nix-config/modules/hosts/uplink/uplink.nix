{ ren, ... }:
{
  ren.host.uplink = {
    system = ren.system.x86_64-linux;
    channel = ren.channel.nixpkgs-master;
    environment = ren.environment.prod;
    system-owner = ren.user.sini;
    system-access-groups = [ ren.group.server-access ];

    networking.interfaces.enp4s0 = {
      ipv4 = [ "10.10.10.1/16" ];
      ipv6 = [ "fe80::3c7a:6eff:fee5:d3a6" ];
    };

    svc-bgp.localAsn = 65000;
    # Break-glass jumpbox: sshd stays publicly reachable (all other hosts are
    # tailnet/LAN-only).
    security-openssh.exposure = "public";
    disk-zfs-disk-single.device_id = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_4TB_S7U8NJ0XC20015K";
    impermanence = {
      wipeRootOnBoot = true;
      wipeHomeOnBoot = true;
    };
    # Always-on Syncthing hub for replicated home dirs (the bgp pattern: the
    # aspect declares the option, the host file sets it).
    network-syncthing-settings-isHub = true;
    # Fleet alerting, mailed straight to Proton (not via the cluster relay).
    svc-monitoring-alertmanager.smtp = {
      host = "smtp.protonmail.ch";
      username = "infra@json64.dev";
      passwordSecret = "smtp-infra-at-json64-dev.age";
    };
    # Credential reset / account recovery mail, through the cluster's Postfix
    # relay to Proton (kubernetes/services/communication/smtp-relay.nix).
    svc-security-kanidm.mailSender = {
      relay = "smtp://smtp.json64.dev:587";
      fromAddress = "infra@json64.dev";
      replyToAddress = "jason@json64.dev";
      instanceDisplayName = "json64";
    };
    # nginx accepts PROXY v2 from the cluster gateway here (kanidm holds
    # 127.0.0.1:8443).
    svc-networking-gateway-upstream = {
      proxyProtocolPort = 8444;
      # The gateway sends PROXY v2 there, so nginx logs the client address.
      proxyProtocol = true;
    };
  };

  ren.aspects.uplink = {
    at = ren.host.uplink;
    includes = with ren.aspects; [
      default
      boot-network-initrd
      disk-zfs-disk-single
      server
      unlock
      nix-builder
      svc-monitoring-alertmanager
      svc-bgp-hub
      svc-networking-headscale
      svc-security-acme
      dns-state-passphrase-age-secrets
      unifi-state-passphrase-age-secrets
      github-state-passphrase-age-secrets
      svc-networking-nginx
      svc-security-kanidm
      svc-networking-gateway-upstream
      svc-media-jellyfin
      svc-web-homepage
      svc-security-oauth2-proxy
      svc-ai-ollama
      svc-ai-open-webui
      svc-nix-attic
      network-tailscale
      network-tailscale-exit-node
      network-syncthing-hub
      svc-web-den-docs-mirror
      svc-web-gen-status
      svc-web-container-registry
      virtualization-podman
      hardware-cpu-amd
      hardware-gpu-intel
    ];
    nixos.facter.reportPath = ../../../hosts/uplink/facter.json;
  };
}
