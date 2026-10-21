# Longhorn dashboard exposure + off-cluster snapshot class. Same aspect as longhorn.nix.
{ ren, ... }:
{
  ren.aspects.k8s-storage-longhorn.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.longhorn.resources = {
        # Off-cluster (type:bak) snapshot class: CNPG ScheduledBackups using
        # it create Longhorn Backups uploaded to the NAS BackupTarget.
        # Coexists with the in-cluster `longhorn-snapshot` (type:snap) class
        # declared in media-pg.nix.
        volumeSnapshotClasses.longhorn-backup-nfs = {
          driver = "driver.longhorn.io";
          deletionPolicy = "Delete";
          parameters.type = "bak";
        };

        httpRoutes.longhorn-dashboard.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "longhorn") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "longhorn"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "longhorn-frontend";
                  port = 80;
                }
              ];
            }
          ];
        };

        securityPolicies."longhorn-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "longhorn-dashboard";
            }
          ];

          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "longhorn";
            clientID = "longhorn";
            clientSecret.name = "longhorn-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.longhorn-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.longhorn-oidc-client-secret.sopsRef;
        };
      };
    };
}
