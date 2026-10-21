# Media PVCs: each pins its statically-provisioned PV by volumeName (nixidy defaults namespace to the application's).
{ ... }:
{
  ren.aspects.k8s-media-base.k8s-manifests =
    { ... }:
    let
      protect."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
    in
    {
      applications.media-base.resources.persistentVolumeClaims = {
        media-scratch-local = {
          metadata.annotations = protect;
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "local-scratch";
            volumeName = "media-scratch-local";
            resources.requests.storage = "800Gi";
          };
        };

        media-scratch-nfs = {
          metadata.annotations = protect;
          spec = {
            accessModes = [ "ReadWriteMany" ];
            storageClassName = "";
            volumeName = "media-scratch-nfs";
            resources.requests.storage = "800Gi";
          };
        };

        media-data-nfs = {
          metadata.annotations = protect;
          spec = {
            accessModes = [ "ReadWriteMany" ];
            storageClassName = "";
            volumeName = "media-data-nfs";
            resources.requests.storage = "1Ti";
          };
        };
      };
    };
}
