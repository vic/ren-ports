{ ren, lib, ... }:
{
  # den settings.core.network.syncthing.isHub; flat field named after the aspect.
  ren.kinds.machine.network-syncthing-settings-isHub =
    ren.lib.opt lib.types.bool false;
}
