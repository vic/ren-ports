{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.hardwarecompatibility-keyboards.nixos =
    {
      globals-defs,
      host,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
      config = {
        users.persistentIds.plugdev = confLib.mkIds 953;
        services.udev.packages =
          with pkgs;
          [
            qmk-udev-rules
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
            vial
            via
          ];
      };
    };
}
