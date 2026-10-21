# Axon k3s cluster: 3-node production cluster, dual-stack. Networks: axon-networks.nix.
{ ren, ... }:
{
  ren.cluster.axon = {
    environment = ren.environment.prod;
    hosts = [
      ren.host.axon-01
      ren.host.axon-02
      ren.host.axon-03
    ];
    role = "k3s";
    kubeVersion = "1.36.1";
    secretPath = ../../../.secrets/clusters/axon;

    # The NAS exports must allow non-privileged ports (Synology), since Cilium
    # masquerade rewrites the client's <1024 source port.
    nfsVolumes.vault-nfs = {
      server = "10.10.10.10";
      share = "/volume2/data";
    };

    # Off-cluster Longhorn backupstore target (NOT a StorageClass).
    nfsVolumes.longhorn-backups = {
      server = "10.10.10.10";
      share = "/volume2/longhorn-backups";
      type = "backup";
    };
  };
}
