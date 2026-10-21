# RomM: retro game ROM manager. Postgres on media-pg (ROMM_DB_DRIVER=postgresql; bare DB_DRIVER is
# ignored and RomM crash-loops speaking mariadb), native Kanidm OIDC (no gateway SecurityPolicy),
# dedicated valkey (romm-redis). Env/OIDC in romm-env.nix, storage+redis in romm-storage.nix,
# CNPs in romm-net.nix, route+secrets in romm-route.nix; replicas/scan knobs are cluster fields
# k8s-media-romm-settings-*. Image: rolling `latest`, digest-pinned in images/rommapp/romm.
{ ren, ... }:
{
  ren.aspects.k8s-media-romm = {
    service-domains = [ "romm" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "romm" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.romm-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/romm-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "romm";
          };
        };

        # RomM auth/credential encryption key: hex length 32 -> 64 hex chars.
        age.secrets.media-romm-auth-secret-key = {
          rekeyFile = environment.secretPath + "/media-romm/auth-secret-key.age";
          generator.script = "hex";
          # settings is a SECRET-level option (agenix-rekey), not generator-level
          settings.length = 32;
          sopsOutput = {
            file = "media-romm";
            key = "auth-secret-key";
          };
        };

        # Redis/valkey password (generated, strong alnum). Run `agenix generate` after this lands.
        age.secrets.media-romm-redis-password = {
          rekeyFile = environment.secretPath + "/media-romm/redis-password.age";
          generator.script = "alnum";
          sopsOutput = {
            file = "media-romm";
            key = "redis-password";
          };
        };

        # Metadata-provider creds: EXTERNALLY issued, NO generator (media-vpn class). Encrypt each
        # to the master recipient, then `agenix rekey`:
        #   printf '%s' "$VALUE" | age -r "$(grep -oP 'age1\S+' .secrets/pub/master.pub)" \
        #     -o .secrets/env/prod/media-romm-metadata/<field>.age
        # Hasheous needs no key (HASHEOUS_API_ENABLED bool only).
        age.secrets.media-romm-metadata-igdb-client-id = {
          rekeyFile = environment.secretPath + "/media-romm-metadata/igdb-client-id.age";
          sopsOutput = {
            file = "media-romm-metadata";
            key = "igdb-client-id";
          };
        };
        age.secrets.media-romm-metadata-igdb-client-secret = {
          rekeyFile = environment.secretPath + "/media-romm-metadata/igdb-client-secret.age";
          sopsOutput = {
            file = "media-romm-metadata";
            key = "igdb-client-secret";
          };
        };
        age.secrets.media-romm-metadata-steamgriddb-api-key = {
          rekeyFile = environment.secretPath + "/media-romm-metadata/steamgriddb-api-key.age";
          sopsOutput = {
            file = "media-romm-metadata";
            key = "steamgriddb-api-key";
          };
        };
        age.secrets.media-romm-metadata-retroachievements-api-key = {
          rekeyFile = environment.secretPath + "/media-romm-metadata/retroachievements-api-key.age";
          sopsOutput = {
            file = "media-romm-metadata";
            key = "retroachievements-api-key";
          };
        };
      };
  };
}
