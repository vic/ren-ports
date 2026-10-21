{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.microvm-host.nixos =
    {
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
      config = lib.mkIf (config.guests != { }) {

        users.persistentIds.microvm = confLib.mkIds 999;
        systemd = {
          services."microvm-macvtap-interfaces@" = {
            after = [ "sys-subsystem-net-devices-vlan\\x2dservices.device" ];
            bindsTo = [ "sys-subsystem-net-devices-vlan\\x2dservices.device" ];
          };
          tmpfiles.settings."15-microvms" = builtins.listToAttrs (
            map (path: {
              name = "${lib.optionalString config.swarselsystems.isImpermanence "/persist"}/microvms/${path}";
              value.d = {
                group = "kvm";
                mode = "0750";
                user = "microvm";
              };
            }) (builtins.attrNames config.guests)
          );
        };

      };
    }

  ;
}
