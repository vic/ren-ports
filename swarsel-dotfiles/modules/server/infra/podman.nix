{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.podman.nixos =
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
      config = {
        swarselsystems.enabledServerModules = [ "podman" ];
        users.persistentIds.podman = confLib.mkIds 969;
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            { directory = "/var/lib/containers"; }
          ];
        };
        networking.nftables.firewall = lib.mkIf config.networking.nftables.enable {

          rules = {
            local-to-podman = {
              before = [ "drop" ];
              from = [
                "local"
                "wgProxy"
                "wgHome"
              ];
              to = [ "podman" ];
              verdict = "accept";
            };
            podman-to-postgres = lib.mkIf config.services.postgresql.enable {
              allowedTCPPorts = [ config.services.postgresql.settings.port ];
              before = [ "drop" ];
              from = [ "podman" ];
              to = [ "local" ];
            };
          };
          zones.podman.interfaces = [ "podman0" ];
        };
        virtualisation = {
          oci-containers.backend = "podman";
          podman.enable = true;
        };

      };
      key = "swarsel/server/podman";
    }

  ;
}
