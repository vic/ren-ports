# bakery: old hosts/nixos/x86_64-linux/bakery/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.bakery = {
    system = ren.system.x86_64-linux;
    isImpermanence = true;
  };
  ren.aspects.bakery.at = ren.host.bakery;
  # old full-build-only imports
  ren.aspects.bakery-full = {
    at = and [
      ren.host.bakery
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.gaming
      ren.aspects.niri
      ren.aspects.noctalia
      ren.aspects.nswitch-rcm
      ren.aspects.profile-personal
      ren.aspects.virtualbox
    ];
  };
  ren.aspects.bakery.nixos =
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
        inputs.nixos-hardware.nixosModules.common-cpu-intel

        ../../hosts/nixos/x86_64-linux/bakery/disk-config.nix
        ../../hosts/nixos/x86_64-linux/bakery/hardware-configuration.nix

      ]
      ++ lib.optionals (!variant.minimal) (
        builtins.attrValues (
          lib.getAttrs [
          ] { }
        )
      );
      swarselsystems = {
        firewall = lib.mkForce true;
        hasBluetooth = true;
        hasFingerprint = true;
        highResolution = "1920x1080";
        info = "Lenovo Ideapad 720S-13IKB";
        isBtrfs = true;
        isCrypted = true;
        isFullBuild = false;
        isLaptop = true;
        isLinux = true;
        isSecureBoot = false;
        isSwap = true;
        lowResolution = "1280x800";
        rootDisk = "/dev/nvme0n1";
        sharescreen = "eDP-1";
        swapSize = "4G";
        wallpaper = sw.root "files/wallpaper/landscape/lenovowp.png";
      };
      topology.self.interfaces = {
        eth1.network = lib.mkForce "home";
        wifi = { };
      };
      home-manager.users."${primaryUser}" = {
        # home.stateVersion = lib.mkForce "23.05";
        swarselsystems.monitors.main = {
          mode = "1920x1080"; # TEMPLATE
          name = "LG Display 0x04EF Unknown";
          output = "eDP-1";
          position = "1920,0";
          scale = "1";
          workspace = "15:L";
        };
      };
    }
    // lib.optionalAttrs (!variant.minimal) { };
}
