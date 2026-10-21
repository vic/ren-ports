# Control plane — the Next.js UI over the dataplane API. Separate release rather
# than a second controller in the dataplane one: it is a different image on a
# different lifecycle, holds no state, wants no PVC, and should be able to
# restart without touching the API.
#
# It exposes no metrics (upstream), so no PodMonitor; probes are tcpSocket (no /health).
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
  inherit (shared) port cpPort;
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { charts, images, ... }:
    {
      applications.hindsight.helm.releases.hindsight-cp = {
        chart = charts.bjw-s-labs.app-template;
        values = {
          controllers.main = {
            type = "deployment";
            replicas = 1;
            pod.labels."den.ai/component" = "hindsight-cp";

            containers.main = {
              image = {
                inherit (images."vectorize-io/hindsight-control-plane") repository digest;
              };

              env = {
                NODE_ENV = "production";
                HINDSIGHT_CP_HOSTNAME = "0.0.0.0";
                HINDSIGHT_CP_PORT = toString cpPort;
                # In-cluster, via the pinned service name.
                HINDSIGHT_CP_DATAPLANE_API_URL = "http://hindsight.ai.svc.cluster.local:${toString port}";
                # The admin token: the CP's server-side API routes send it as
                # `Authorization: Bearer` on every dataplane call
                # (src/lib/hindsight-client.ts at the pinned version), so a
                # user the gateway admits has full access with no token of
                # their own. HINDSIGHT_CP_ACCESS_KEY stays unset: the gateway's
                # admin-only OIDC is the authorization.
                HINDSIGHT_CP_DATAPLANE_API_KEY.valueFrom.secretKeyRef = {
                  name = "hindsight-cp-admin-token";
                  key = "token";
                };
              };

              probes = {
                liveness = {
                  enabled = true;
                  custom = true;
                  spec = {
                    tcpSocket.port = cpPort;
                    initialDelaySeconds = 30;
                    periodSeconds = 10;
                  };
                };
                readiness = {
                  enabled = true;
                  custom = true;
                  spec = {
                    tcpSocket.port = cpPort;
                    initialDelaySeconds = 10;
                    periodSeconds = 5;
                  };
                };
              };

              ports = [
                {
                  name = "http";
                  containerPort = cpPort;
                }
              ];

              resources = {
                requests = {
                  cpu = "50m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "1000m";
                  memory = "1Gi";
                };
              };
            };
          };

          # ClusterIP only. The CP holds the admin token, so its one way in
          # is the gateway's admin-only route (hindsight-route.nix); no
          # LoadBalancer, no NodePort.
          service.main = {
            controller = "main";
            forceRename = "hindsight-cp";
            ports.http.port = cpPort;
          };
        };
      };
    };
}
