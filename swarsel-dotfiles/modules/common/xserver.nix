{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.xserver.nixos.config.services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };
}
