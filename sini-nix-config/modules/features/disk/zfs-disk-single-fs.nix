{ ... }:
{
  ren.aspects.disk-zfs-disk-single.nixos.fileSystems = {
    "/" = {
      device = "zroot/local/root";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/nix" = {
      device = "zroot/local/nix";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/home" = {
      device = "zroot/local/home";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist" = {
      device = "zroot/local/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/cache" = {
      device = "zroot/local/cache";
      fsType = "zfs";
      neededForBoot = true;
    };
  };
}
