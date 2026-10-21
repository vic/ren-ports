{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.firezone-client.nixos =
    {
      globals-defs,
      host,
      config,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {

        users.persistentIds.firezone-client = confLib.mkIds 955;
        services.firezone.gui-client = {
          inherit (config.node) name;
          enable = true;
          allowedUsers = [ mainUser ];
        };
      };
    };
}
