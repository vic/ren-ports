# liliputsteps: old hosts/nixos/aarch64-linux/liliputsteps/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.liliputsteps = {
    system = ren.system.aarch64-linux;
    isCloud = true;
    isImpermanence = true;
    nodeRoles = [ "jumphost" ];
  };
  ren.aspects.liliputsteps.at = ren.host.liliputsteps;
  ren.aspects.liliputsteps.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.liliputsteps-full = {
    at = and [
      ren.host.liliputsteps
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.bastion
      ren.aspects.profile-localserver
    ];
  };
  ren.aspects.liliputsteps.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    {
      imports = [
        ../../hosts/nixos/aarch64-linux/liliputsteps/hardware-configuration.nix
        ../../hosts/nixos/aarch64-linux/liliputsteps/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = false;
        mainUser = "jump";
        rootDisk = "/dev/disk/by-id/scsi-360fb180663ec4f2793a763a087d46885";
      };
      topology.self = {
        icon = "devices.cloud-server";
        interfaces.ProxyJump = {
          physicalConnections = [
            (config.lib.topology.mkConnection "moonside" "lan")
            (config.lib.topology.mkConnection "twothreetunnel" "lan")
            (config.lib.topology.mkConnection "belchsfactory" "lan")
            (config.lib.topology.mkConnection "stoicclub" "lan")
            (config.lib.topology.mkConnection "eagleland" "wan")
          ];
          virtual = true;
        };
      };
    }
    // lib.optionalAttrs (!variant.minimal) {

      # users.users.swarsel.enable = lib.mkForce false;
      # home-manager.users.swarsel.enable = lib.mkForce false
    };
}
