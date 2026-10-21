# twothreetunnel: old hosts/nixos/aarch64-linux/twothreetunnel/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.twothreetunnel = {
    system = ren.system.aarch64-linux;
    nodeRoles = [ "webProxy" "oauthServer" ];
    isCloud = true;
    isImpermanence = true;
  };
  ren.aspects.twothreetunnel.at = ren.host.twothreetunnel;
  ren.aspects.twothreetunnel.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.twothreetunnel-full = {
    at = and [
      ren.host.twothreetunnel
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.acme
      ren.aspects.crowdsec
      ren.aspects.firezone
      ren.aspects.nginx
      ren.aspects.nginx-exporter
      ren.aspects.nginx-otel
      ren.aspects.oauth2-proxy
      ren.aspects.profile-localserver
      ren.aspects.wireguard
    ];
  };
  ren.aspects.twothreetunnel.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    {
      imports = [
        ../../hosts/nixos/aarch64-linux/twothreetunnel/hardware-configuration.nix
        ../../hosts/nixos/aarch64-linux/twothreetunnel/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "VM.Standard.A1.Flex, 2 vCPUs, 8GB RAM";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = false;
        rootDisk = "/dev/disk/by-id/scsi-3608deb9b0d4244de95c6620086ff740d";
      };
      topology.self.icon = "devices.cloud-server";
      globals.wireguard.wgProxy = {
        clients = [
          "moonside"
          "stoicclub"
          "winters"
          "summers"
          "summers-ankisync"
          "summers-atuin"
          "summers-audio"
          "summers-firefly"
          "summers-forgejo"
          "summers-freshrss"
          "summers-homebox"
          "summers-immich"
          "summers-jellyfin"
          "summers-kanidm"
          "summers-kavita"
          "summers-koillection"
          "summers-matrix"
          "summers-mealie"
          "summers-monitoring"
          "summers-nextcloud"
          "summers-paperless"
          "summers-radicale"
          "summers-storage"
          "belchsfactory"
          "eagleland"
          "hintbooth-adguardhome"
        ];
        netConfigPrefix = config.node.name;
        server = config.node.name;
      };
    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables = {
        chains.forward.dnat = {
          after = [ "conntrack" ];
          rules = [ "ct status dnat accept" ];
        };
        firewall.zones.untrusted.interfaces = [ "lan" ];
      };

    };
}
