# moonside: old hosts/nixos/aarch64-linux/moonside/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.moonside = {
    system = ren.system.aarch64-linux;
    isCloud = true;
    isImpermanence = true;
    nodeRoles = [ "webSyncthingServer" ];
    proxyHost = "twothreetunnel";
  };
  ren.aspects.moonside.at = ren.host.moonside;
  ren.aspects.moonside.includes = [
    ren.aspects.nix-topology-self
    ren.aspects.systemd-networkd-server
  ];
  # old full-build-only imports
  ren.aspects.moonside-full = {
    at = and [
      ren.host.moonside
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.copyparty
      ren.aspects.croc
      ren.aspects.firefox-syncserver
      ren.aspects.invidious
      ren.aspects.microbin
      ren.aspects.minecraft
      ren.aspects.profile-localserver
      ren.aspects.restic
      ren.aspects.searx
      ren.aspects.server-syncthing
      ren.aspects.shlink
      ren.aspects.shopservatory
      ren.aspects.slink
      ren.aspects.wireguard
    ];
  };
  ren.aspects.moonside.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    let
      inherit (config.repo.secrets.local.syncthing)
        dev1
        dev2
        dev3
        devices
        loc1
        ;
    in
    {
      imports = [
        ../../hosts/nixos/aarch64-linux/moonside/hardware-configuration.nix
        ../../hosts/nixos/aarch64-linux/moonside/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
        isBtrfs = true;
        isCrypted = false;
        isLinux = true;
        isSecureBoot = false;
        isSwap = false;
        rootDisk = "/dev/sda";
        server.restic.targets.SwarselMoonside = {
          paths = [
            "/persist/opt/minecraft"
          ];
          repository = config.repo.secrets.local.resticRepo;
        };
      };
      globals.services.syncthing-moonside.extraConfig = {
        dataDir = "/sync";
        extraDevices = devices;
        extraFolders = {
          "${loc1}" = {
            devices = [
              dev1
              dev2
              dev3
            ];
            id = "5gsxv-rzzst";
            path = "/sync/${loc1}";
            type = "sendreceive";
            versioning = {
              params.keep = "3";
              type = "simple";
            };
          };
          Documents = {
            devices = [ "pyramid" ];
            id = "hgr3d-pfu3w";
            path = "/sync/Documents";
            type = "receiveonly";
            versioning = {
              params.keep = "2";
              type = "simple";
            };
          };
          runandbun = {
            devices = [
              "pyramid"
              "magicant"
            ];
            id = "kwnql-ev64v";
            path = "/sync/runandbun";
            type = "receiveonly";
            versioning = {
              params.keep = "5";
              type = "simple";
            };
          };
        };
      };
      system.stateVersion = "23.11";
    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
    };
}
