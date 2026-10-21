# matrix-admin: Ketesa (formerly synapse-admin) plus the Synapse admin API on
# matrix-admin.json64.dev, behind Envoy gateway OIDC (kanidm `admins`).
#
# Two locks: the gateway admits only kanidm `admins`, and Synapse still requires
# an admin token on every /_synapse/admin call. Ketesa obtains it by logging in
# through MAS (mas.nix), which grants the admin scope only to kanidm `admins`.
# forwardAccessToken stays false: the gateway must not overwrite the
# Authorization header, which carries the Synapse token. Routes in
# matrix-admin-route.nix.
{ ren, lib, ... }:
{
  ren.aspects.k8s-communication-matrix-admin = {
    service-domains = [ "matrix-admin" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "matrix-admin" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.synapse-admin-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/synapse-admin-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "synapse-admin";
          };
        };
      };

    k8s-manifests =
      { cluster, charts, images, ... }:
      {
        applications.matrix-admin = {
          namespace = "matrix";

          helm.releases.matrix-admin = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                replicas = 1;
                containers.main = {
                  image = {
                    inherit (images."etkecc/ketesa") repository digest;
                  };
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
                # The image EXPOSEs 80 but sets SERVER_PORT=8080.
                ports.http.port = 8080;
              };
              persistence.config = {
                type = "configMap";
                name = "matrix-admin-config";
                globalMounts = [
                  {
                    path = "/var/public/config.json";
                    subPath = "config.json";
                    readOnly = true;
                  }
                ];
              };
            };
          };

          resources.configMaps.matrix-admin-config.data."config.json" = builtins.toJSON {
            restrictBaseUrl = [ "https://${ren.helpers.clusterDomainFor cluster "matrix-admin"}" ];
            externalAuthProvider = true;
          };
        };
      };
  };
}
