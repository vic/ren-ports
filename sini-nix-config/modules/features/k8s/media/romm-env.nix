# RomM controller + env: scan knobs (cluster fields), media-pg DB, native Kanidm OIDC, valkey, providers.
{ ren, ... }:
{
  ren.aspects.k8s-media-romm.k8s-manifests =
    { cluster, charts, images, ... }:
    {
      applications.romm = {
        namespace = "media";

        helm.releases.romm = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            controllers.main = {
              type = "deployment";
              # Extra replicas do NOT speed a single scan (SCAN_WORKERS does); >1 needs RWX userdata.
              replicas = cluster.k8s-media-romm-settings-replicas;
              containers.main = {
                image = {
                  inherit (images."rommapp/romm") repository digest;
                };
                env = {
                  TZ = "America/Los_Angeles";
                  PUID = "1027";
                  PGID = "65536";

                  # SCAN_TIMEOUT caps one scan job; SCAN_WORKERS is the asyncio concurrency (default 1 = serial).
                  SCAN_TIMEOUT = toString cluster.k8s-media-romm-settings-scanTimeout;
                  SCAN_WORKERS = toString cluster.k8s-media-romm-settings-scanWorkers;

                  ROMM_DB_DRIVER = "postgresql";
                  DB_HOST = "media-pg-rw";
                  DB_PORT = "5432";
                  DB_NAME = "romm";
                  DB_USER.valueFrom.secretKeyRef = {
                    name = "media-pg-romm-password";
                    key = "username";
                  };
                  DB_PASSWD.valueFrom.secretKeyRef = {
                    name = "media-pg-romm-password";
                    key = "password";
                  };

                  ROMM_AUTH_SECRET_KEY.valueFrom.secretKeyRef = {
                    name = "media-romm";
                    key = "auth-secret-key";
                  };

                  # Native OIDC (kanidm); replaces the gateway SecurityPolicy.
                  OIDC_ENABLED = "true";
                  OIDC_AUTOLOGIN = "true";
                  OIDC_PROVIDER = "kanidm"; # display label only
                  OIDC_CLIENT_ID = "romm";
                  OIDC_CLIENT_SECRET.valueFrom.secretKeyRef = {
                    name = "romm-oidc-client-secret";
                    key = "client-secret";
                  };
                  OIDC_REDIRECT_URI = "https://${ren.helpers.clusterDomainFor cluster "romm"}/api/oauth/openid";
                  OIDC_SERVER_APPLICATION_URL = "https://${ren.helpers.clusterDomainFor cluster "romm"}";
                  OIDC_SERVER_METADATA_URL = "${(ren.helpers.oidcProviderFor cluster "romm").issuer}/.well-known/openid-configuration";
                  # kanidm `roles` claim: media.admins -> admin, media.access -> user. RomM also requests
                  # `roles` as a scope, so the kanidm romm client scopeMap must grant it.
                  OIDC_CLAIM_ROLES = "roles";
                  OIDC_ROLE_ADMIN = "admin";
                  OIDC_ROLE_VIEWER = "user";

                  # Without this the SPA is gated behind the first-run wizard until an admin row exists
                  # and OIDC autologin cannot pass; off => first media.admins OIDC login creates the admin.
                  DISABLE_SETUP_WIZARD = "true";

                  # Valkey for sessions + RQ scan queue + cache; default 127.0.0.1 would run degraded.
                  REDIS_HOST = "romm-redis";
                  REDIS_PORT = "6379";
                  REDIS_PASSWORD.valueFrom.secretKeyRef = {
                    name = "media-romm";
                    key = "redis-password";
                  };
                };
                envFrom = [ ];
              };
            };

            service.main = {
              controller = "main";
              ports.http.port = 8080;
            };
          };
        };
      };
    };
}
