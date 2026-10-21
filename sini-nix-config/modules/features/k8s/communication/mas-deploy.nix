# mas pod: server deployment, service and mounts (syn2mas import in mas-import.nix).
{ lib, ... }:
let
  secretFile = path: key: {
    inherit path;
    subPath = key;
    readOnly = true;
  };
in
{
  ren.aspects.k8s-communication-matrix-mas.k8s-manifests =
    { charts, images, ... }:
    {
      applications.matrix-authentication-service = {
        namespace = "matrix";

        helm.releases.matrix-authentication-service = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            defaultPodOptions.securityContext = {
              runAsNonRoot = true;
              runAsUser = 65532; # the image's distroless nonroot user
              runAsGroup = 65532;
            };
            controllers.main = {
              type = "deployment";
              replicas = 1;
              containers.main = {
                image = {
                  inherit (images."element-hq/matrix-authentication-service") repository digest;
                };
                args = [
                  "server"
                  "--config"
                  "/config/config.yaml"
                  "--config"
                  "/secrets/secrets.yaml"
                ];
                probes = lib.genAttrs [ "liveness" "readiness" ] (_: {
                  enabled = true;
                  custom = true;
                  spec.httpGet = {
                    path = "/health";
                    port = 8080;
                  };
                });
              };
            };
            service.main = {
              controller = "main";
              ports.http.port = 8080;
            };
            persistence = {
              config = {
                type = "configMap";
                name = "matrix-authentication-service-config";
                globalMounts = [ { path = "/config"; } ];
              };
              secrets = {
                type = "secret";
                name = "matrix-mas";
                globalMounts = [
                  (secretFile "/secrets/secrets.yaml" "secrets.yaml")
                  (secretFile "/secrets/encryption-key" "encryption-key")
                  (secretFile "/secrets/signing.key" "signing.key")
                  (secretFile "/secrets/shared-secret" "shared-secret")
                ];
              };
              oidc = {
                type = "secret";
                name = "synapse-oidc-client-secret";
                globalMounts = [ (secretFile "/secrets/oidc-client-secret" "client-secret") ];
              };
            };
          };
        };
      };
    };
}
