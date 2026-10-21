# services: nextcloud
{ ren, ... }:
{
  ren.aspects.services-nextcloud.nixos =
    {
      config,
      fleet,
      pkgs,
      ...
    }:
    let
      tailnet = fleet.tailnet;
      serviceName = "nextcloud";
      hostName = "${serviceName}.${tailnet}";
    in
    {
      imports = [
        # To allow setting `services.nextcloud.webserver = "caddy";`.
        "${
          fetchTarball {
            # url = "https://github.com/onny/nixos-nextcloud-testumgebung/archive/f97c7e1cd7a995e476cc81f36083dfb21b02e588.tar.gz";
            url = "https://github.com/Adda0/nixos-nextcloud-caddy/archive/main.tar.gz";
            sha256 = "sha256:1jj544iw9kjj82pac7apk5lgdmf9mzsn480gyw2sfaawvqkwkn96";
          }
        }/nextcloud-extras.nix"
      ];

      services.nextcloud = {
        enable = true;
        webserver = "caddy";
        # hostName = "${hostName}:${toString port}";
        inherit hostName;
        config = {
          adminpassFile = "/etc/${serviceName}-admin-pass";
          adminuser = "admin";

          # Nextcloud PostegreSQL database configuration, recommended over using SQLite
          dbtype = "pgsql";
          dbuser = serviceName;
          # dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
          dbname = serviceName;
          # dbpassFile = "/var/nextcloud-db-pass";

        };
        # Suggested by Nextcloud's health check.
        # phpOptions."opcache.interned_strings_buffer" = "16";
        # Need to manually increment with every major upgrade.
        package = pkgs.nextcloud35;
        database.createLocally = true;
        settings = {
          # Further forces Nextcloud to use HTTPS.
          overwriteProtocol = "https";

          default_phone_region = "CS";
          trusted_domains = [
            "localhost"
            "${serviceName}.${tailnet}"
            "0.0.0.0"
            "127.0.0.1"
          ];
          trusted_proxies = [
            "localhost"
            "127.0.0.1"
            "0.0.0.0"
          ];
        };
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps)
            # news
            bookmarks
            calendar
            contacts
            end_to_end_encryption
            gpoddersync
            music
            notes
            tasks
            # onlyoffice
            # cookbook
            # qownnotesapi
            ;
          # UnifiedPush Provider.
          uppush = pkgs.fetchNextcloudApp {
            appName = "uppush";
            appVersion = "2.6.1";
            license = "agpl3Plus";
            url = "https://codeberg.org/NextPush/uppush/archive/2.6.1.tar.gz";
            hash = "sha256-aCvBQLJVkdy9ha0NPrJ3008hIyZJ7/dzA7iyjUr/Tes=";
          };

          # # Custom app example.
          # socialsharing_telegram = pkgs.fetchNextcloudApp rec {
          #   url = "https://github.com/nextcloud-releases/socialsharing/releases/download/v3.0.1/socialsharing_telegram-v3.0.1.tar.gz";
          #   license = "agpl3";
          #   sha256 = "sha256-8XyOslMmzxmX2QsVzYzIJKNw6rVWJ7uDhU1jaKJ0Q8k=";
          # };
        };

        # Let NixOS install and configure the database automatically.
        # database.createLocally = true;
        # Let NixOS install and configure Redis caching automatically.
        configureRedis = true;
        # Increase the maximum file upload size.
        # maxUploadSize = "16G";
        https = true;
        autoUpdateApps.enable = true;
        extraAppsEnable = true;
      };
      environment.etc."${serviceName}-admin-pass".text = "01234567890";

      services.postgresql = {
        enable = true;
        # Ensure the database, user, and permissions always exist
        ensureDatabases = [ serviceName ];
        ensureUsers = [
          {
            name = serviceName;
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services = {
        # Ensure that postgres is running before running the setup
        "nextcloud-setup" = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
          # RequiresMountsFor lives in [Unit], not [Service]; putting it in serviceConfig
          #  made systemd log "Unknown key 'RequiresMountsFor' in section [Service], ignoring"
          #  and silently dropped the dependency.
          unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud" ];
        };

        # PostgreSQL stamps every database with the glibc collation version it was created
        #  with. After a glibc bump the recorded version no longer matches what the OS
        #  provides, so every connection prints a "collation version mismatch" warning and
        #  indexes over text columns may be ordered by the old rules. The documented remedy
        #  is to rebuild those indexes and then re-record the version; gate it on an actual
        #  mismatch so an ordinary switch does not reindex the whole database every time.
        "postgresql-refresh-collation-${serviceName}" = {
          description = "Refresh PostgreSQL collation version for ${serviceName}";
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
          before = [ "nextcloud-setup.service" ];
          wantedBy = [ "nextcloud-setup.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
          };
          script =
            let
              psql = "${config.services.postgresql.package}/bin/psql";
            in
            ''
              stale=$(${psql} -tAXq -d ${serviceName} -c \
                "SELECT datcollversion IS NOT NULL AND datcollversion <> pg_database_collation_actual_version(oid) FROM pg_database WHERE datname = '${serviceName}';")
              if [ "$stale" = t ]; then
                echo "collation version drifted, reindexing ${serviceName}"
                ${psql} -XqAt -d ${serviceName} -c 'REINDEX DATABASE ${serviceName};'
                ${psql} -XqAt -d ${serviceName} -c 'ALTER DATABASE ${serviceName} REFRESH COLLATION VERSION;'
              fi
            '';
        };

        # FIXME:
        # Automated certificate renewal
        # tailscale-cert-renewal =
        #   let
        #     sslCertificateFile = ../../../certs/mensa-nixos.rohu-ling.ts.net.crt;
        #     sslCertificateKeyFile = ../../../certs/mensa-nixos.rohu-ling.ts.net.key;
        #   in
        #   {
        #     description = "Run 'tailscale cert' to update certs";
        #     after = [ "network.target" ];
        #     script = ''
        #       #!/usr/bin/env bash
        #       set -xeou pipefail
        #       ${lib.getExe pkgs.tailscale} cert --cert-file ${sslCertificateFile} --key-file ${sslCertificateKeyFile} ${hostName}
        #       # chown nginx:nginx ${sslCertificateFile}
        #       # chown nginx:nginx ${sslCertificateKeyFile}
        #       chown caddy:caddy ${sslCertificateFile}
        #       chown caddy:caddy ${sslCertificateKeyFile}
        #       # Restart nginx service so that new certs are used
        #       # systemctl try-restart nginx.service
        #       systemctl try-restart caddy.service
        #     '';
        #     serviceConfig = {
        #       Type = "oneshot";
        #     };
        #   };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

    };

  ren.aspects.services-nextcloud.service-domains = { ... }: config: {
    subdomain = "nextcloud";
    extraConfig = /* caddyfile */ ''
      # reverse_proxy https://${config.services.nextcloud.hostName} {
      #   header_up X-Webauth-User {http.auth.user.tailscale_user} # Forwards your Tailscale user ID to Nextcloud. Usually your email address.
      # }
    '';
  };
}
