# belchsfactory: old hosts/nixos/aarch64-linux/belchsfactory/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.belchsfactory = {
    system = ren.system.aarch64-linux;
    isCloud = true;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.belchsfactory.at = ren.host.belchsfactory;
  ren.aspects.belchsfactory.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.belchsfactory-full = {
    at = and [
      ren.host.belchsfactory
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.attic
      ren.aspects.buildbot
      ren.aspects.garage
      ren.aspects.profile-localserver
      ren.aspects.remotebuild
      ren.aspects.ssh-builder
      ren.aspects.wireguard
    ];
  };
  ren.aspects.belchsfactory.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    {
      imports = [
        ../../hosts/nixos/aarch64-linux/belchsfactory/hardware-configuration.nix
        ../../hosts/nixos/aarch64-linux/belchsfactory/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];

      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = false;
        rootDisk = "/dev/sda";
        server.garage = {
          buckets = [
            "attic"
          ];
          data_dir = {
            capacity = "150G";
            path = "/var/lib/garage/data";
          };
          keys.nixos = [
            "attic"
          ];
        };
      };

      topology.self.icon = "devices.cloud-server";

      # use SSH key with own limits for nixbuild.net instead of the general one in remotebuild.nix
      sops.secrets.nixbuild-net-key = lib.mkForce {
        inherit (config.swarselsystems) sopsFile;
        mode = "0400";
      };

      node.lockFromBootstrapping = lib.mkForce false;
    };
}
