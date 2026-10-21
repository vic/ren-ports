{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.gvfs.nixos.config.services.gvfs.enable = true;
}
