# Media namespace foundations, scratch half: scratch storage tiers (NVMe local PV + NFS PV, from
# media-scratch-exports). PVs pinned to PVCs via claimRef, protected with ArgoCD Prune=false,Delete=false.
# NAS data PV (media-data-nfs): base-nas.nix.
{ lib, ... }:
{
  ren.aspects.k8s-media-base.k8s-manifests =
    { media-scratch-exports, ... }:
    let
      scratch = lib.head media-scratch-exports;
      protect."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
    in
    {
      applications.media-base = {
        namespace = "media";
        # Namespace + storage tiers before the app fleet (wave 0) lands in them.
        annotations."argocd.argoproj.io/sync-wave" = "-1";

        resources = {
          # No provisioner: the PV is statically declared below.
          storageClasses.local-scratch = {
            provisioner = "kubernetes.io/no-provisioner";
            volumeBindingMode = "WaitForFirstConsumer";
          };

          persistentVolumes = {
            media-scratch-local = {
              metadata.annotations = protect;
              spec = {
                capacity.storage = "800Gi";
                accessModes = [ "ReadWriteOnce" ];
                persistentVolumeReclaimPolicy = "Retain";
                storageClassName = "local-scratch";
                local.path = scratch.exportPath;
                claimRef = {
                  namespace = "media";
                  name = "media-scratch-local";
                };
                nodeAffinity.required.nodeSelectorTerms = [
                  {
                    matchExpressions = [
                      {
                        key = "kubernetes.io/hostname";
                        operator = "In";
                        values = [ scratch.hostname ];
                      }
                    ];
                  }
                ];
              };
            };

            media-scratch-nfs = {
              metadata.annotations = protect;
              spec = {
                capacity.storage = "800Gi";
                accessModes = [ "ReadWriteMany" ];
                persistentVolumeReclaimPolicy = "Retain";
                storageClassName = "";
                nfs = {
                  server = scratch.ip;
                  path = scratch.exportPath;
                };
                mountOptions = [
                  "nfsvers=4.1"
                  "noatime"
                  "soft"
                  "timeo=50"
                ];
                claimRef = {
                  namespace = "media";
                  name = "media-scratch-nfs";
                };
              };
            };
          };
        };
      };
    };
}
