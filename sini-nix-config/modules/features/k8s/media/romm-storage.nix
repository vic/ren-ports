# RomM storage + valkey. library = read-only ROM-project canonical builds (VALIDATION phase; flip
# subPath to the production library + drop readOnly once validated). resources = regenerable metadata
# cache on the NAS. userdata = non-regenerable saves/config on replicated longhorn (media-config backup).
{ ... }:
{
  ren.aspects.k8s-media-romm.k8s-manifests =
    { charts, ... }:
    {
      applications.romm = {
        helm.releases.romm.values.persistence = {
          # Structure A: {library}/roms/{platform}; each canonical <slug> dir becomes a platform.
          library = {
            type = "persistentVolumeClaim";
            existingClaim = "media-data-nfs";
            globalMounts = [
              {
                path = "/romm/library/roms";
                subPath = "rom-project/canonical";
                readOnly = true;
              }
              # Firmware/BIOS from {library}/bios/{platform_fs_slug}; slugs already equal RomM fs_slugs.
              {
                path = "/romm/library/bios";
                subPath = "rom-project/bios";
                readOnly = true;
              }
            ];
          };

          resources = {
            type = "persistentVolumeClaim";
            existingClaim = "media-data-nfs";
            globalMounts = [
              {
                path = "/romm/resources";
                subPath = "rom-project/romm-metadata/resources";
              }
            ];
          };

          userdata = {
            type = "persistentVolumeClaim";
            existingClaim = "romm-userdata";
            globalMounts = [
              {
                path = "/romm/assets";
                subPath = "assets";
              }
              {
                path = "/romm/config";
                subPath = "config";
              }
            ];
          };
        };

        # Ephemeral valkey (official chart), ACL auth from media-romm/redis-password; fullnameOverride
        # pins the Service name to romm-redis (= REDIS_HOST).
        helm.releases.romm-redis = {
          chart = charts.valkey.valkey;
          values = {
            fullnameOverride = "romm-redis";
            auth = {
              enabled = true;
              usersExistingSecret = "media-romm";
              aclUsers.default = {
                permissions = "~* &* +@all";
                passwordKey = "redis-password";
              };
            };
            persistence.enabled = false;
            service.port = 6379;
          };
        };

        # 20Gi is nominal (longhorn is thin-provisioned) so savestates never run out.
        resources.persistentVolumeClaims.romm-userdata = {
          metadata.labels."recurring-job-group.longhorn.io/media-config" = "enabled";
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "longhorn";
            resources.requests.storage = "20Gi";
          };
        };
      };
    };
}
