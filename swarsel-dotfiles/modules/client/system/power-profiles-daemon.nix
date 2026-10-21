{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.power-profiles-daemon.nixos.config.services.power-profiles-daemon.enable = true;
}
