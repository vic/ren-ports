{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.hardwarecompatibility-ledger.nixos =
    {
      pkgs,
      ...
    }:
    {
    config = {
      services.udev.packages = with pkgs; [
        ledger-udev-rules
      ];
      hardware.ledger.enable = true;
    };
  };
}
