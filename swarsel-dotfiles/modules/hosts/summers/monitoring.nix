# summers-monitoring: old hosts/nixos/x86_64-linux/summers/guests/monitoring/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-monitoring = {
    isImpermanence = true;
    nodeRoles = [ "monitoringServer" ];
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-monitoring.at = ren.guest.summers-monitoring;
  ren.aspects.summers-monitoring.includes = [
    ren.aspects.gotify
    ren.aspects.grafana
    ren.aspects.loki
    ren.aspects.mimir
    ren.aspects.profile-microvm
    ren.aspects.pyroscope
    ren.aspects.tempo
  ];
  ren.aspects.summers-monitoring.nixos =
    {
      variant,
      lib,
      ...
    }:
    {
      imports = [
      ];

      swarselsystems = {
        isMicroVM = true;
      };

    }
    // lib.optionalAttrs (!variant.minimal) {

      microvm = {
        mem = 1024 * 24;
        vcpu = 8;
      };

    };
}
