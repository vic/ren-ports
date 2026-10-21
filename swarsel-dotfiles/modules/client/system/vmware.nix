{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.vmware.nixos.config.virtualisation.vmware = {
    guest.enable = true;
    host.enable = true;
  };
}
