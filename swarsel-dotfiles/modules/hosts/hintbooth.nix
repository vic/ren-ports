# hintbooth: old hosts/nixos/x86_64-linux/hintbooth/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.hintbooth = {
    system = ren.system.x86_64-linux;
    nodeRoles = [ "homeProxy" "routerServer" ];
    isImpermanence = true;
  };
  ren.aspects.hintbooth.at = ren.host.hintbooth;
  ren.aspects.hintbooth.includes = [
    ren.aspects.microvm-host
    ren.aspects.systemd-networkd-server-home
  ];
  # old full-build-only imports
  ren.aspects.hintbooth-full = {
    at = and [
      ren.host.hintbooth
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.profile-localserver
      ren.aspects.profile-router
      ren.aspects.smartctl-exporter
      ren.aspects.wireguard
    ];
  };
  ren.guest.hintbooth-adguardhome = {
    system = ren.system.x86_64-linux;
    on = ren.host.hintbooth;
    guestName = "adguardhome";
  };
  ren.guest.hintbooth-nginx = {
    system = ren.system.x86_64-linux;
    on = ren.host.hintbooth;
    guestName = "nginx";
  };
  ren.aspects.hintbooth.nixos =
    {
      variant,
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {

      imports = [
        ../../hosts/nixos/x86_64-linux/hintbooth/hardware-configuration.nix
        ../../hosts/nixos/x86_64-linux/hintbooth/disk-config.nix

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "HUNSN RM02, 8GB RAM";
        initrdVLAN = "home";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = true;
        localVLANs = map (name: "${name}") (builtins.attrNames globals.networks.home-lan.vlans);
        networkKernelModules = [ "igb" ];
        rootDisk = "/dev/sda";
        swapSize = "8G";
        withMicroVMs = true;
      };
      topology.self.interfaces = {
        lan2.physicalConnections = [
          {
            interface = "lan";
            node = "summers";
          }
        ];
        lan3.physicalConnections = [
          {
            interface = "bmc";
            node = "summers";
          }
        ];
        lan4.physicalConnections = [
          {
            interface = "eth1";
            node = "switch-bedroom";
          }
        ];
        lan5.physicalConnections = [
          {
            interface = "eth1";
            node = "switch-livingroom";
          }
        ];
      };
      globals.wireguard.wgHome = {
        clients = [
          "hintbooth-adguardhome"
          "hintbooth-nginx"
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
          "summers-transmission"
          "winters"
        ];
        netConfigPrefix = "home";
        server = config.node.name;
      };

    }
    // lib.optionalAttrs (!variant.minimal) {


    };
}
