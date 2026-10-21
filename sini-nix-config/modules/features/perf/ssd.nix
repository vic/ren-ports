# ssd: SSD fstrim service.
{ ... }:
{
  ren.aspects.perf-ssd.nixos.services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
