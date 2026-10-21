# helpers: machine directories, logins, and the old confLib.mkMicrovm (a guest inside its host's `guests`).
{ ren, inputs, ... }:
let
  sw = ren.helpers;
  configDirOf =
    m:
    if m ? on then
      configDirOf m.on + "/guests/${m.guestName}"
    else
      inputs.self + "/hosts/nixos/${m.system.name}/${if m.configName == null then m.name else m.configName}";
  # old node.secretsDir: a guest keeps its secrets in its host's secrets dir
  secretsDirOf =
    m: if m ? on then configDirOf m.on + "/secrets/${m.guestName}" else configDirOf m + "/secrets";
in
{
  ren.helpers = {
    inherit configDirOf;
    inherit secretsDirOf;
    loginOf = u: if u.login == null then u.name else u.login;

    mkMicrovm =
      {
        config,
        lib,
        globals,
        guest,
        ms,
      }:
      let
        inherit (guest) guestName withZfs eternorPaths;
      in
      {
        ${guestName} = {
          autostart = true;
          backend = "microvm";
          extraSpecialArgs = {
            inherit (guest.system.legacyPackages) lib;
            microVMParent = config.node.name;
          };
          microvm = {
            baseMac = config.repo.secrets.local.networking.networks.lan.mac;
            interfaces.vlan-services.mac = lib.mkForce "02:${
              lib.substring 3 5 config.guests.${guestName}.microvm.baseMac
            }:${(sw.confLibOf { host = guest.on; inherit globals; }).mkDeviceMac globals.networks.home-lan.vlans.services.hosts.${guest.name}.id}";
            system = config.node.arch;
          };
          modules = ms ++ [
            {
              fileSystems = {
                "/persist".neededForBoot = true;
              }
              // lib.optionalAttrs withZfs {
                "/state".neededForBoot = true;
              };
              networking.nftables.firewall.zones.untrusted.interfaces = lib.mkIf (
                lib.length config.guests.${guestName}.networking.links == 1
              ) config.guests.${guestName}.networking.links;
              node = {
                configDir = configDirOf guest;
                secretsDir = secretsDirOf guest;
              };
            }
          ];
          zfs = lib.mkIf withZfs (
            {
              # other stuff that should only reside on zfs, not backed up remotely
              "/persist" = {
                dataset = "guests/${guestName}/persist";
                pool = "Vault";
              };
              # stateful config usually bind-mounted to /var/lib/ that should be backed up remotely
              "/state" = {
                dataset = "guests/${guestName}/state";
                pool = "Vault";
              };
            }
            // lib.optionalAttrs (eternorPaths != [ ]) (
              lib.listToAttrs (
                map
                  # data that is pulled in externally by services, some of which is backed up externally
                  (
                    eternorPath:
                    lib.nameValuePair "/storage/${eternorPath}" {
                      dataset = "Eternor/${eternorPath}";
                      pool = "Vault";
                    }
                  )
                  eternorPaths
              )
            )
          );
        };
      };
  };
}
