# Lidarr storage: shared media data PVC (/data), NFS scratch PVC (/scratch) for imports, and
# MediaCover on the NAS (pre-staged from the archive; bulk re-fetchable artwork keyed by DB id,
# kept off the longhorn config PVC, which has headroom for thumbnails regardless).
{ ... }:
{
  ren.aspects.k8s-media-lidarr.k8s-manifests =
    { ... }:
    {
      applications.lidarr.helm.releases.lidarr.values.persistence = {
        data = {
          type = "persistentVolumeClaim";
          existingClaim = "media-data-nfs";
          globalMounts = [ { path = "/data"; } ];
        };
        scratch = {
          type = "persistentVolumeClaim";
          existingClaim = "media-scratch-nfs";
          globalMounts = [ { path = "/scratch"; } ];
        };
        metadata = {
          type = "persistentVolumeClaim";
          existingClaim = "media-data-nfs";
          globalMounts = [
            {
              path = "/config/MediaCover";
              subPath = "media/metadata/lidarr/MediaCover";
            }
          ];
        };
      };
    };
}
