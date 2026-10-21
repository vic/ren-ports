# kernel: XanMod desktop-latency kernel
{ ren, ... }:
{
  # XanMod: a desktop-latency kernel (different scheduler tuning, higher tick rate, extra patches). Worth it in front of
  # a keyboard; probably not useful on a server or in a container, for scheduling behaviour the hypervisor overrides anyway.
  ren.aspects.kernel-xanmod.nixos =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
    };
}
