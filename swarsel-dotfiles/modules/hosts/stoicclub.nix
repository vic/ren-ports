# stoicclub: old hosts/nixos/aarch64-linux/stoicclub/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.stoicclub = {
    system = ren.system.aarch64-linux;
    nodeRoles = [ "dnsServer" "acmeDnsServer" ];
    isCloud = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.stoicclub.at = ren.host.stoicclub;
  ren.aspects.stoicclub.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.stoicclub-full = {
    at = and [
      ren.host.stoicclub
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.acme-dns
      ren.aspects.nsd
      ren.aspects.profile-localserver
      ren.aspects.wireguard
    ];
  };
  ren.aspects.stoicclub.nixos =
    {
      variant,
      lib,
      ...
    }:
    {
      imports = [
        ../../hosts/nixos/aarch64-linux/stoicclub/hardware-configuration.nix
        ../../hosts/nixos/aarch64-linux/stoicclub/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
        isBastionTarget = true;
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = false;
        rootDisk = "/dev/disk/by-id/scsi-360e1a5236f034316a10a97cc703ce9e3";
      };
      topology.self.icon = "devices.cloud-server";

    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
    };
}
