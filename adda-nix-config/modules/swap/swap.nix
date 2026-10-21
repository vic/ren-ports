# Swap: a host's `swap` record turns on zram, swapspace and a swapfile (with zswap in front of it).
{ ren, ... }:
let
  inherit (ren.lib) and when;
  on =
    f:
    and [
      ren.kinds.host
      (when f)
    ];
in
{
  ren.aspects.zram = {
    at = on (s: s.host.swap.zram != null);
    nixos =
      { host, ... }:
      {
        zramSwap = {
          enable = true;
          inherit (host.swap.zram) algorithm memoryPercent;
          priority = 5;
        };
      };
  };
  # no priority option: the kernel assigns a low (negative) priority
  ren.aspects.swapspace = {
    at = on (s: s.host.swap.swapspace);
    nixos.services.swapspace.enable = true;
  };
  ren.aspects.swapfile = {
    at = on (s: s.host.swap.swapfile != null);
    nixos =
      { host, ... }:
      {
        swapDevices = [
          {
            device = host.swap.swapfile.path;
            size = host.swap.swapfile.sizeGiB * 1024;
            priority = 1;
            options = [ "discard" ];
          }
        ];
      };
  };
  ren.aspects.zswap = {
    at = on (s: s.host.swap.swapfile != null && s.host.swap.swapfile.zswap);
    nixos.boot.zswap = {
      enable = true;
      maxPoolPercent = 50;
    };
  };
}
