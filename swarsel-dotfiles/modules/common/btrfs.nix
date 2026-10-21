{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.btrfs.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "btrfs" ];
        boot.supportedFilesystems = lib.mkIf config.swarselsystems.isBtrfs [ "btrfs" ];
      };
    };
}
