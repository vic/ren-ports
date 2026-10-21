# Settings for the garage aspect group: per cluster, ren.cluster.<name>.k8s-storage-garage-settings-storageBackend.
{ ren, lib, ... }:
{
  ren.kinds.cluster.k8s-storage-garage-settings-storageBackend = ren.lib.opt (lib.types.enum [
    "longhorn"
    "hybrid"
    "local-path"
  ]) "longhorn";
  # Garage backing storage. Garage RF=3 owns cross-node redundancy, so the
  # volume must NOT double-replicate (the default `longhorn` StorageClass is
  # 2-replica = 6 copies under RF3 - deliberately avoided).
  #   longhorn   = data+meta on longhorn-single (1 Longhorn replica; off-cluster
  #                NFS backup; survives reset-axon).
  #   hybrid     = data on longhorn-single (backed up); LMDB meta on node-local
  #                local-path (peer-protected, not in the backup set).
  #   local-path = both node-local; Garage RF=3 the only redundancy; NO volume
  #                backup (DR needs a backup cluster).
}
