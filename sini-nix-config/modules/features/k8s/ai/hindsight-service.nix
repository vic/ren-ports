# hindsight dataplane services, volumes and the write-gate ConfigMap.
{ ren, lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
  inherit (shared) port gateDir tokensDir adminDir;
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { cluster, ... }:
    {
      applications.hindsight.helm.releases.hindsight.values = {
        service.main = {
          controller = "main";
          # Pin to `hindsight`: bjw-s suffixes every service with its
          # identifier once a controller owns >1 service, so adding the
          # LoadBalancer below would otherwise rename this to
          # `hindsight-main` and move the in-cluster address under every
          # existing consumer. Same reason shoko.nix pins its own.
          forceRename = "hindsight";
          ports.http.port = port;
        };

        # Private-network reach on a kubernetes-loadbalancers address,
        # BGP-advertised to the LAN and not internet-routable — the shoko
        # idiom. This is how workstations and off-cluster agents reach the
        # bank without a public HTTPRoute and without the OIDC gateway,
        # which headless MCP clients cannot complete anyway.
        #
        # NOTE: anything on the LAN that can route here reads and writes every
        # bank outside gatedBanks and reads the ones without gateReads; the
        # rest needs the bank's token. The CiliumNetworkPolicies admit the callers.
        service.internal = {
          controller = "main";
          type = "LoadBalancer";
          externalTrafficPolicy = "Local";
          annotations."lbipam.cilium.io/ips" = ren.helpers.getAssignment cluster "hindsight-internal";
          ports.http.port = port;
        };

        persistence = {
          # HuggingFace cache for the local embedder (~130 MB) and
          # reranker (~90 MB), so they are fetched once rather than on
          # every pod start. Upstream mounts the cache at this path.
          model-cache = {
            type = "persistentVolumeClaim";
            accessMode = "ReadWriteOnce";
            size = "5Gi";
            storageClass = "longhorn";
            globalMounts = [ { path = "/home/hindsight/.cache"; } ];
          };

          write-gate = {
            type = "configMap";
            identifier = "write-gate";
            advancedMounts.main.main = [
              {
                path = "${gateDir}/hindsight_write_gate.py";
                subPath = "hindsight_write_gate.py";
                readOnly = true;
              }
            ];
          };

          # One file per gated bank and per reader. 0440 with the pod's fsGroup 1000 makes
          # them readable by the image's uid 1000 and no one else in the pod.
          write-tokens = {
            type = "secret";
            name = "hindsight-write-tokens";
            defaultMode = 288; # 0440
            advancedMounts.main.main = [
              {
                path = tokensDir;
                readOnly = true;
              }
            ];
          };

          # The admin token's SHA-256 only; the token is the CP's.
          admin-digest = {
            type = "secret";
            name = "hindsight-cp-admin-token-sha256";
            defaultMode = 288; # 0440
            advancedMounts.main.main = [
              {
                path = adminDir;
                readOnly = true;
              }
            ];
          };
        };

        configMaps.write-gate.data."hindsight_write_gate.py" = builtins.readFile ./_hindsight/hindsight-write-gate.py;
      };
    };
}
