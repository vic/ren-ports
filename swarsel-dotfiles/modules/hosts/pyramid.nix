# pyramid: old hosts/nixos/x86_64-linux/pyramid/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.pyramid = {
    system = ren.system.x86_64-linux;
    isImpermanence = false;
  };
  ren.aspects.pyramid.at = ren.host.pyramid;
  # old full-build-only imports
  ren.aspects.pyramid-full = {
    at = and [
      ren.host.pyramid
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.amdcpu
      ren.aspects.amdgpu
      ren.aspects.framework
      ren.aspects.gaming
      ren.aspects.hibernation
      ren.aspects.niri
      ren.aspects.noctalia
      ren.aspects.nswitch-rcm
      ren.aspects.profile-personal
      ren.aspects.virtualbox
      ren.aspects.work
    ];
  };
  ren.aspects.pyramid.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    let
      primaryUser = config.swarselsystems.mainUser;
    in
    {

      imports = [
        inputs.nixos-hardware.nixosModules.framework-16-7040-amd

        ../../hosts/nixos/x86_64-linux/pyramid/disk-config.nix
        ../../hosts/nixos/x86_64-linux/pyramid/hardware-configuration.nix

      ]
      ++ lib.optionals (!variant.minimal) (
        builtins.attrValues (
          lib.getAttrs [
          ] { }
        )
      );
      swarselsystems = {
        inherit (config.repo.secrets.local) hostName;
        inherit (config.repo.secrets.local) fqdn;
        firewall = lib.mkForce true;
        hasBluetooth = true;
        hasFingerprint = true;
        hibernation.offset = 533760;
        highResolution = "2560x1600";
        info = "Framework Laptop 16, 7940HS, RX7700S, 64GB RAM";
        isBtrfs = true;
        isCrypted = true;
        isLaptop = true;
        isLinux = true;
        isSecureBoot = true;
        lowResolution = "1280x800";
        sharescreen = "eDP-2";
        wallpaper = sw.root "files/wallpaper/landscape/lenovowp.png";
        wifiMac = config.repo.secrets.local.network.wifiMac;
      };
      topology.self.interfaces = {
        eth1.network = lib.mkForce "home";
        fritz-wg.network = "fritz-wg";
        wifi = { };
      };
      home-manager.users."${primaryUser}".swarselsystems = {
        SecondaryGpuCard = "pci-0000_03_00_0";
        cpuCount = 16;
        isSecondaryGpu = true;
        monitors.main = {
          mode = "2560x1600";
          # name = "BOE 0x0BC9 Unknown";
          name = "BOE 0x0BC9";
          output = "eDP-2";
          position = "2560,0";
          scale = "1";
          workspace = "15:L";
        };
        temperatureHwmon = {
          input-filename = "temp4_input";
          isAbsolutePath = true;
          path = "/sys/devices/virtual/thermal/thermal_zone0/";
        };
      };
    }
    // lib.optionalAttrs (!variant.minimal) {

      networking.nftables.firewall.zones.untrusted.interfaces = [
        "wlan*"
        "enp*"
        "eth*"
      ];
      # networking.nftables = {
      #   enable = lib.mkForce false;
      #   firewall.enable = lib.mkForce false;
      # };
    };
}
