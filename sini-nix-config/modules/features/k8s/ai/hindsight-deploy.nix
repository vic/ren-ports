# hindsight dataplane: the app-template release, controller, probes, resources.
# Env is in hindsight-env.nix; services, volumes, gate ConfigMap in hindsight-service.nix.
{ lib, ... }:
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { charts, images, ... }:
    let
      shared = import ./_hindsight/shared.nix { inherit lib; };
      inherit (shared) port;
    in
    {
      applications.hindsight.helm.releases.hindsight = {
        chart = charts.bjw-s-labs.app-template;
        values.controllers.main = {
          type = "deployment";

          # Single replica, deliberately. Retain work is claimed in
          # async_operations under HINDSIGHT_API_WORKER_ID, and the
          # in-process worker (HINDSIGHT_API_WORKER_ENABLED, default true)
          # is the only consumer — a second replica would need the
          # separate worker StatefulSet upstream ships for that case.
          replicas = 1;

          # The image drops to USER hindsight (uid/gid 1000 — `useradd -m`
          # in upstream's Dockerfile, and its own comment says 1000), but a
          # freshly provisioned PVC mounts root-owned 0755. The model cache
          # lands on one, so the embedder's first write fails with
          # "PermissionError at /home/hindsight/.cache/huggingface".
          # fsGroup makes the kubelet chown the volume to this GID and add
          # it to the container's supplementary groups; OnRootMismatch
          # keeps it from re-walking the whole cache on every start.
          pod.securityContext = {
            fsGroup = 1000;
            fsGroupChangePolicy = "OnRootMismatch";
          };

          # Release anything the previous incarnation of this worker was
          # holding. A pod that dies mid-retain (OOM, node loss, the crash
          # loop this deployment already went through) leaves its tasks in
          # 'processing' forever — the document sits in the bank with its
          # facts unextracted, which is silently unreachable by recall.
          # Graceful shutdown releases them; ungraceful termination is the
          # gap this closes.
          #
          # Only safe to do unconditionally because WORKER_ID is pinned and
          # replicas = 1: there is never another live worker whose tasks
          # this could steal. It is `|| true` on purpose — on a first
          # deploy the tables do not exist yet (migrations run in the main
          # container, after this), and a best-effort cleanup must never
          # block the startup that would create them.
          initContainers.release-stale-tasks = {
            image = {
              inherit (images."vectorize-io/hindsight-api") repository digest;
            };
            command = [
              "sh"
              "-c"
              "hindsight-admin decommission-worker hindsight --yes || echo 'release-stale-tasks: skipped (see error above)'"
            ];
            env.HINDSIGHT_API_DATABASE_URL.valueFrom.secretKeyRef = {
              name = "hindsight-pg-dsn";
              key = "url";
            };
          };

          containers.main = {
            image = {
              inherit (images."vectorize-io/hindsight-api") repository digest;
            };

            ports = [
              {
                name = "http";
                containerPort = port;
              }
            ];

            # ~2Gi resident under load with both local models in-process
            # (upstream's hardware table); the ceiling leaves room for a
            # large retain, whose in-flight extraction state is bounded by
            # HINDSIGHT_API_RETAIN_MEMORY_BUDGET_MB (default 128).
            resources = {
              requests = {
                cpu = "200m";
                memory = "1Gi";
              };
              limits = {
                cpu = "2000m";
                memory = "4Gi";
              };
            };
          };
        };
      };
    };
}
