# tuwunel: companion Matrix homeserver for server_name gen.wtf, served at
# matrix.gen.wtf, run beside Synapse (json64.dev) to compare the two.
#
# Single binary + embedded RocksDB on a Longhorn PVC; no Postgres. Login is
# kanidm OIDC (tuwunel's identity_provider), accounts created on first login for
# `matrix.access` members. Password registration is off.
#
# Delegation: the gen.wtf apex is GitHub Pages (sini/gen docs), not this
# cluster, so the /.well-known/matrix documents must be served there (or a
# _matrix-fed._tcp.gen.wtf SRV record used). Until then federation for gen.wtf
# does not resolve; clients can still use https://matrix.gen.wtf directly.
# Config in tuwunel-config.nix, route and CNPs in tuwunel-route.nix.
{ ren, lib, ... }:
{
  ren.aspects.k8s-communication-matrix-tuwunel = {
    # matrix.gen.wtf, via prod services.tuwunel.domain.
    service-domains = [ "tuwunel" ];
    served-domains = { cluster, ... }:
      ren.helpers.clusterServedDomains cluster {
        services = [ "tuwunel" ];
        proxied = false; # grey: Matrix federation does not work through the Cloudflare proxy
      };

    age-secrets =
      { environment, ... }:
      {
        age.secrets.tuwunel-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/tuwunel-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "tuwunel";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.tuwunel = {
          namespace = "matrix";

          helm.releases.tuwunel = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              # Upstream (docs/deploying/kubernetes.md): the first boot after an
              # upgrade may run a one-time DB migration with the listener closed;
              # a kill part-way leaves it half migrated. Generous grace period, and
              # a startup probe that holds off liveness/readiness until it serves.
              defaultPodOptions.terminationGracePeriodSeconds = 600;
              controllers.main = {
                type = "deployment";
                replicas = 1;
                strategy = "Recreate";
                containers.main = {
                  image = {
                    inherit (images."matrix-construct/tuwunel") repository digest;
                  };
                  args = [
                    "-c"
                    "/config/tuwunel.toml"
                  ];
                  probes =
                    lib.genAttrs [ "liveness" "readiness" ] (_: {
                      enabled = true;
                      custom = true;
                      spec.httpGet = {
                        path = "/_matrix/client/versions";
                        port = 8008;
                      };
                    })
                    // {
                      startup = {
                        enabled = true;
                        custom = true;
                        spec = {
                          httpGet = {
                            path = "/_matrix/client/versions";
                            port = 8008;
                          };
                          periodSeconds = 10;
                          failureThreshold = 180; # up to 30 minutes of migration
                        };
                      };
                    };
                };
              };
            };
          };
        };
      };
  };
}
