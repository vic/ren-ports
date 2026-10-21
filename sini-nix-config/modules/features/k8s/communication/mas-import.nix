# mas syn2mas import Job and the Synapse config it mounts. Done; stays disabled.
_:
let
  # The one-time import from Synapse. Done; true renders its Job again.
  syn2mas = false;
  secretFile = path: key: {
    inherit path;
    subPath = key;
    readOnly = true;
  };
in
{
  ren.aspects.k8s-communication-matrix-mas.k8s-manifests =
    { images, ... }:
    {
      applications.matrix-authentication-service.helm.releases.matrix-authentication-service.values = {
        # The import, run with Synapse stopped and MAS not serving. No
        # `syn2mas check` step: it exits non-zero on warnings, and migrate runs
        # the same checks and stops only on errors.
        controllers.syn2mas-migrate = {
          enabled = syn2mas;
          type = "job";
          # Jobs are immutable: each migration step is its own Job.
          forceRename = "mas-syn2mas-migrate";
          job.backoffLimit = 0;
          pod.restartPolicy = "Never";
          containers.main = {
            image = {
              inherit (images."element-hq/matrix-authentication-service") repository digest;
            };
            args = [
              "syn2mas"
              "migrate"
              "--config"
              "/config/config.yaml"
              "--config"
              "/secrets/secrets.yaml"
              "--synapse-config"
              "/synapse/homeserver.yaml"
              "--synapse-config"
              "/synapse/secrets.yaml"
            ];
          };
        };
        persistence = {
          # Synapse's config, for the import only.
          synapse-config = {
            enabled = syn2mas;
            type = "configMap";
            name = "synapse-config";
            advancedMounts.syn2mas-migrate.main = [ (secretFile "/synapse/homeserver.yaml" "homeserver.yaml") ];
          };
          synapse-secrets = {
            enabled = syn2mas;
            type = "secret";
            name = "matrix-synapse";
            advancedMounts.syn2mas-migrate.main = [ (secretFile "/synapse/secrets.yaml" "secrets.yaml") ];
          };
        };
      };
    };
}
