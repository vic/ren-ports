# synapse: the Matrix homeserver for server_name json64.dev, served at
# matrix.json64.dev (federation on 443 via .well-known delegation from the apex).
#
# server_name is PERMANENT: it is part of every user id, room alias and the
# federation signing identity. Do not change it without standing up a new server.
#
# Authentication is delegated to MAS (mas.nix), which logs users in through
# kanidm and creates accounts on first login for members of `matrix.access`.
# Synapse only checks MAS's tokens; the gateway only routes, because Matrix
# clients and federating servers must reach /_matrix unauthenticated.
#
# Config is split in two files merged by Synapse (--config-path twice): the
# non-secret homeserver.yaml (synapse-config.nix) and secrets.yaml composed by a
# template-file age secret (synapse-secrets.nix). The MAS shared secret and the
# signing key are mounted as files. /_synapse/admin is deliberately NOT routed:
# use `kubectl port-forward`. Routes in synapse-route.nix, CNPs in synapse-net.nix.
{ ren, lib, ... }:
{
  ren.aspects.k8s-communication-matrix-synapse = {
    service-domains = [ "matrix" ];
    served-domains = { cluster, ... }:
      ren.helpers.clusterServedDomains cluster {
        services = [ "matrix" ];
        proxied = false; # grey: Matrix federation does not work through the Cloudflare proxy
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.synapse = {
          namespace = "matrix";

          helm.releases.synapse = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              defaultPodOptions.securityContext = {
                runAsUser = 991; # the matrixdotorg/synapse image's synapse user
                runAsGroup = 991;
                fsGroup = 991;
                fsGroupChangePolicy = "OnRootMismatch";
              };
              controllers.main = {
                type = "deployment";
                replicas = 1;
                strategy = "Recreate";
                containers.main = {
                  image = {
                    inherit (images."matrixdotorg/synapse") repository digest;
                  };
                  command = [
                    "python"
                    "-m"
                    "synapse.app.homeserver"
                  ];
                  args = [
                    "--config-path"
                    "/config/homeserver.yaml"
                    "--config-path"
                    "/secrets/secrets.yaml"
                  ];
                  probes = lib.genAttrs [ "liveness" "readiness" ] (_: {
                    enabled = true;
                    custom = true;
                    spec.httpGet = {
                      path = "/health";
                      port = 8008;
                    };
                  });
                };
              };
              service.main = {
                controller = "main";
                ports.http.port = 8008;
              };
            };
          };
        };
      };
  };
}
