# winters: old hosts/nixos/x86_64-linux/winters/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.winters = {
    system = ren.system.x86_64-linux;
    isImpermanence = false;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.winters.at = ren.host.winters;
  ren.aspects.winters.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.winters-full = {
    at = and [
      ren.host.winters
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.profile-localserver
      ren.aspects.smartctl-exporter
    ];
  };
  ren.aspects.winters.nixos =
    {
      variant,
      globals-defs,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
    in
    {

      imports = [
        ../../hosts/nixos/x86_64-linux/winters/hardware-configuration.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "ASRock J4105-ITX, 32GB RAM";
        isBtrfs = false;
        isCrypted = false;
        isLinux = true;
        isSecureBoot = false;

      };
      topology.self.interfaces.eth1 = { };
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      networking.hosts = {
        ${globals.networks.home-lan.hosts.hintbooth.ipv4} = [ "server.hintbooth.${globals.domains.main}" ];
        ${globals.networks.home-lan.hosts.hintbooth.ipv6} = [ "server.hintbooth.${globals.domains.main}" ];
      };

    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables.firewall.zones.untrusted.interfaces = [
        "lan"
        "enp3s0"
      ];

    };
}
