# synapse volume mounts: config, secrets, MAS shared secret and data PVC.
_: {
  ren.aspects.k8s-communication-matrix-synapse.k8s-manifests = { ... }: {
    applications.synapse.helm.releases.synapse.values.persistence = {
        config = {
          type = "configMap";
          name = "synapse-config";
          globalMounts = [ { path = "/config"; } ];
        };
        secrets = {
          type = "secret";
          name = "matrix-synapse";
          globalMounts = [
            {
              path = "/secrets/secrets.yaml";
              subPath = "secrets.yaml";
              readOnly = true;
            }
            {
              path = "/secrets/signing.key";
              subPath = "signing.key";
              readOnly = true;
            }
          ];
        };
        mas = {
          type = "secret";
          name = "matrix-mas";
          globalMounts = [
            {
              path = "/secrets/mas-shared-secret";
              subPath = "shared-secret";
              readOnly = true;
            }
          ];
        };
        data = {
          type = "persistentVolumeClaim";
          existingClaim = "synapse-data";
          globalMounts = [ { path = "/data"; } ];
        };
    };
  };
}
