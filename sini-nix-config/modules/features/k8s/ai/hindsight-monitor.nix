# hindsight PodMonitor and the Secrets the pods mount.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { config, ... }:
    {
      # Raw PodMonitor: no typed accessor without a kube-prometheus-stack
      # CRDs bridge, so author it directly (mirrors the monitoring aspect).
      # The API serves Prometheus format at /metrics on its own port.
      applications.hindsight.objects = [
        {
          apiVersion = "monitoring.coreos.com/v1";
          kind = "PodMonitor";
          metadata = {
            name = "hindsight";
            namespace = "ai";
          };
          spec = {
            selector.matchLabels."app.kubernetes.io/name" = "hindsight";
            podMetricsEndpoints = [
              {
                port = "http";
                path = "/metrics";
                interval = "30s";
                # Default instance is the ephemeral pod IP:port, which
                # churns on every restart; pin it to the stable app name.
                relabelings = [
                  {
                    sourceLabels = [ "__meta_kubernetes_pod_label_app_kubernetes_io_name" ];
                    targetLabel = "instance";
                  }
                ];
              }
            ];
          };
        }
      ];

      # The nixidy objectTransform rewrites each Secret → SopsSecret; each value
      # is a sops ref resolved at render time. hindsight-write-tokens holds one
      # key per gated bank and one per reader (the name predates read gating and is kept so the
      # deployed object is not replaced).
      applications.hindsight.resources.secrets = {
        hindsight-write-tokens = {
          type = "Opaque";
          stringData =
            lib.genAttrs shared.gatedBankNames (bank: config.age.secrets.${shared.tokenSecret bank}.sopsRef)
            // lib.listToAttrs (
              map (
                t: lib.nameValuePair t.key config.age.secrets."hindsight-${t.name}".sopsRef
              ) shared.readerTokens
            );
        };
        hindsight-cp-admin-token-sha256 = {
          type = "Opaque";
          stringData.sha256 = config.age.secrets.hindsight-cp-admin-token-sha256.sopsRef;
        };
        hindsight-cp-admin-token = {
          type = "Opaque";
          stringData.token = config.age.secrets.hindsight-cp-admin-token.sopsRef;
        };
        hindsight-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.hindsight-oidc-client-secret.sopsRef;
        };
      };
    };
}
