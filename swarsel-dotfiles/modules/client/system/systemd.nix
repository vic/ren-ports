{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.systemd.nixos.config.systemd.settings.Manager = {
    DefaultTimeoutStartSec = "60s";
    DefaultTimeoutStopSec = "15s";
  };
}
