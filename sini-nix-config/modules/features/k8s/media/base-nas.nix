# Media namespace foundations, NAS half: media-data-nfs PV (library from cluster.nfsVolumes.vault-nfs), pinned to
# its PVC via claimRef and protected with ArgoCD Prune=false,Delete=false. Scratch half: base.nix.
{ ... }:
{
  ren.aspects.k8s-media-base.k8s-manifests =
    { cluster, ... }:
    {
      applications.media-base.resources.persistentVolumes.media-data-nfs = {
        metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
        spec = {
          capacity.storage = "1Ti";
          accessModes = [ "ReadWriteMany" ];
          persistentVolumeReclaimPolicy = "Retain";
          storageClassName = "";
          nfs = {
            server = cluster.nfsVolumes.vault-nfs.server;
            path = cluster.nfsVolumes.vault-nfs.share;
          };
          mountOptions = [
            "nfsvers=4.1"
            "noatime"
          ];
          claimRef = {
            namespace = "media";
            name = "media-data-nfs";
          };
        };
      };
    };
}
