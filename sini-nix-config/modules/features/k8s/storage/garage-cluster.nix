# GarageCluster - 3-node, RF=3, auto-layout, k8s peer discovery, ClusterIP.
# The operator (garage-operator.nix) reconciles this single CR into the storage
# StatefulSet, Services, garage.toml, and PodDisruptionBudget.
#
# Field paths follow the storage version of the GarageCluster CRD (v1beta2).
# The nixidy typed accessor (`resources.garageClusters`) derives the apiVersion
# from the registered CRD, so this file writes only the spec.
{ ... }:
{
  ren.aspects.k8s-storage-garage-cluster.k8s-manifests =
    { cluster, ... }:
    let
      storageBackend = cluster.k8s-storage-garage-settings-storageBackend;
      # Garage RF=3 owns redundancy, so never the 2-replica default class.
      dataClass = if storageBackend == "local-path" then "local-path" else "longhorn-single";
      metaClass = if storageBackend == "longhorn" then "longhorn-single" else "local-path";
    in
    {
      # Anchor the shared app namespace here (every garage aspect merges into
      # applications.garage; identical-string namespace is conflict-free).
      applications.garage.namespace = "garage";
      applications.garage.resources = {
        garageClusters.garage.spec = {
          zone = "axon";
          storage = {
            replicas = 3;
            data = {
              size = "50Gi";
              storageClassName = dataClass;
            };
            metadata = {
              size = "5Gi";
              storageClassName = metaClass;
            };
          };
          database.engine = "lmdb"; # CRD enum: lmdb (default) | sqlite | fjall.
          replication.factor = 3;
          discovery.kubernetes.enabled = true;
          layoutManagement = {
            autoApply = true;
            minNodesHealthy = 2;
          };
          layoutPolicy = "Auto";
          network = {
            rpcBindPort = 3901;
            service.type = "ClusterIP";
            # rpc-secret / admin-token from secrets.nix: 32-byte hex.
            rpcSecretRef = {
              name = "garage-rpc-secret";
              key = "rpc-secret";
            };
          };
          admin = {
            bindPort = 3903;
            adminTokenSecretRef = {
              name = "garage-admin-token";
              key = "admin-token";
            };
          };
          s3Api = {
            bindPort = 3900;
            region = "garage";
            # Leading dot enables vhost-style (bucket.<rootDomain>) Host matching.
            rootDomain = ".s3.json64.dev";
          };
          # Website endpoint (:3902) for static-site buckets (sites.nix).
          webApi = {
            enabled = true;
            bindPort = 3902;
            rootDomain = ".web.json64.dev";
          };
        };

        # NB: the operator creates and OWNS the cluster Services (`garage` s3
        # :3900 / admin :3903 / web :3902, `garage-headless` rpc :3901). Do NOT
        # hand-declare them: a duplicate collides with the operator's and leaves
        # the ArgoCD app permanently OutOfSync.
      };
    };
}
