# CPU power: a host's `cpuPower` picks one handler; power-profiles-daemon (and tlp) stay off.
{ ren, inputs, ... }:
let
  handler =
    n:
    ren.lib.and [
      ren.kinds.host
      (ren.lib.when (s: s.host.cpuPower == n))
    ];
in
{
  ren.aspects.auto-cpufreq = {
    at = handler "auto-cpufreq";
    nixos = {
      imports = [ inputs.auto-cpufreq.nixosModules.default ];
      services.power-profiles-daemon.enable = false;
      # Settings: https://github.com/AdnanHodzic/auto-cpufreq (defaults in use).
      programs.auto-cpufreq.enable = true;
    };
  };
  ren.aspects.watt = {
    at = handler "watt";
    nixos = {
      services.power-profiles-daemon.enable = false;
      services.tlp.enable = false;
      services.watt = {
        enable = true;
        # See https://github.com/NotAShelf/watt/blob/main/docs/configuring.md.
        settings = { };
      };
    };
  };
}
