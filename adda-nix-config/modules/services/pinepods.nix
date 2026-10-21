# services: pinepods
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.services-pinepods.nixos =
    {
      config,
      fleet,
      host,
      lib,
      ...
    }:
    let
      serviceName = "pinepods";
      hostName = "${serviceName}.${fleet.tailnet}";
      dataDir = "/var/lib/pinepods";
      envFile = config.sops.secrets.pinepods-env.path;

      podUnitName = "podman-pod-${serviceName}";
      containerNames = [
        "pinepods-db"
        "pinepods-valkey"
        "pinepods-app"
      ];
    in
    {
      # No nixpkgs package exists for PinePods (multi-component Rust/WASM app +
      #  Postgres + Valkey, shipped upstream as a Docker Compose stack) — run it
      #  via the podman/oci-containers backend already set up by the
      #  `virtualisation` aspect instead of a native `services.pinepods`.
      virtualisation.oci-containers.backend = "podman";

      virtualisation.oci-containers.containers = {
        pinepods-db = {
          image = "docker.io/library/postgres:18";
          environment = {
            POSTGRES_DB = "pinepods_database";
            POSTGRES_USER = "postgres";
            PGDATA = "/var/lib/pgdata/pgdata";
          };
          environmentFiles = [ envFile ];
          volumes = [ "${dataDir}/pgdata:/var/lib/pgdata" ];
          extraOptions = [ "--pod=${serviceName}" ];
        };

        pinepods-valkey = {
          image = "docker.io/valkey/valkey:8-alpine";
          extraOptions = [ "--pod=${serviceName}" ];
        };

        pinepods-app = {
          image = "docker.io/madeofpendletonwool/pinepods:0.9.0";
          extraOptions = [ "--pod=${serviceName}" ];
          environment = {
            DB_TYPE = "postgresql";
            DB_HOST = "127.0.0.1";
            DB_PORT = "5432";
            DB_USER = "postgres";
            DB_NAME = "pinepods_database";
            VALKEY_HOST = "127.0.0.1";
            VALKEY_PORT = "6379";
            # Both point at the Caddy/Tailscale-fronted URL: HOSTNAME is used for
            #  RSS callbacks, but rootless-podman-under-systemd is known to
            #  clobber it with the container name, so SERVER_URL (checked first,
            #  never overridden by the runtime) is set too.
            HOSTNAME = "https://${hostName}";
            SERVER_URL = "https://${hostName}";
            SEARCH_API_URL = "https://search.pinepods.online/api/search";
            PEOPLE_API_URL = "https://people.pinepods.online";
            USERNAME = "adda";
            FULLNAME = (builtins.head host.users).realName;
            EMAIL = "adda@example.com"; # TODO: set before first boot
            DEBUG_MODE = "false";
          };
          environmentFiles = [ envFile ];
          volumes = [
            "${dataDir}/downloads:/opt/pinepods/downloads"
            "${dataDir}/backups:/opt/pinepods/backups"
          ];
          # No `ports` here: a pod member cannot publish its own, the pod does it.
          dependsOn = [
            "pinepods-db"
            "pinepods-valkey"
          ];
        };
      };

      # aardvark-dns is off host-wide (see the `virtualisation` aspect), so the three
      #  containers cannot look each other up by name. They are one application, so
      #  give them one network namespace instead of a DNS server: inside the pod they
      #  reach each other on 127.0.0.1, and only the pod publishes a port.
      systemd.services = {
        ${podUnitName} = {
          description = "Podman pod for ${serviceName}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # `--replace` keeps this idempotent across reboots and activations:
            #  the pod outlives its containers in podman's state, and the member
            #  units below are `partOf` it, so they are recreated with it.
            ExecStart = lib.concatStringsSep " " [
              "${config.virtualisation.podman.package}/bin/podman pod create"
              "--replace"
              "--name ${serviceName}"
              "--infra-name ${serviceName}-infra"
              "--publish 127.0.0.1:8040:8040"
            ];
            ExecStop = "${config.virtualisation.podman.package}/bin/podman pod rm --force --ignore ${serviceName}";
          };
        };
      }
      // lib.genAttrs (map (name: "podman-${name}") containerNames) (_: {
        after = [ "${podUnitName}.service" ];
        requires = [ "${podUnitName}.service" ];
        partOf = [ "${podUnitName}.service" ];
      });

      # The postgres image drops to its own `postgres` account (uid/gid 999, baked
      #  into the image) before creating $PGDATA, so the bind-mount host directory
      #  has to be owned by that numeric id — a name here would resolve against the
      #  host's passwd, not the container's. `getent passwd 999` on the host happens
      #  to be `fwupd-refresh`; the two are unrelated, only the number is shared, and
      #  nothing on either side resolves the other's name. The remaining two are
      #  mounted into the app container, which stays root.
      systemd.tmpfiles.rules = [
        "d ${dataDir}/pgdata 0700 999 999 -"
        "d ${dataDir}/downloads 0750 root root -"
        "d ${dataDir}/backups 0750 root root -"
      ];

      # Populate with `sops secrets/pinepods.env`:
      #   POSTGRES_PASSWORD=<db password>
      #   DB_PASSWORD=<same db password, PinePods' own var name for it>
      #   PASSWORD=<initial admin password>
      # One shared dotenv file handed to both containers is simpler than
      #  keeping two files' passwords in sync; each container ignores the
      #  variables meant for the other.
      sops.secrets.pinepods-env = {
        sopsFile = addax.secretsPath "pinepods.env";
        format = "dotenv";
      };
    };

  ren.aspects.services-pinepods.service-domains = { ... }: _: {
    subdomain = "pinepods";
    extraConfig = ''
      reverse_proxy localhost:8040
    '';
  };
}
