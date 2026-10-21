# eagleland: old hosts/nixos/x86_64-linux/eagleland/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.eagleland = {
    system = ren.system.x86_64-linux;
    isCloud = true;
    isImpermanence = true;
  };
  ren.aspects.eagleland.at = ren.host.eagleland;
  ren.aspects.eagleland.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.eagleland-full = {
    at = and [
      ren.host.eagleland
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.mailserver
      ren.aspects.profile-localserver
      ren.aspects.wireguard
    ];
  };
  ren.aspects.eagleland.nixos =
    {
      variant,
      lib,
      ...
    }:
    {
      imports = [
        ../../hosts/nixos/x86_64-linux/eagleland/hardware-configuration.nix
        ../../hosts/nixos/x86_64-linux/eagleland/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "2vCPU, 4GB Ram";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = true;
        proxyHost = "twothreetunnel"; # mail shall not be proxied through twothreetunnel
        rootDisk = "/dev/sda";
        swapSize = "4G";

      };
      topology.self.icon = "devices.cloud-server";
    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables.firewall.zones.untrusted.interfaces = [ "wan" ];

    };
}
