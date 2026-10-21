# The llama-server controller (StatefulSet) of one instance.
{ shared, images }:
inst:
let
  inherit (shared) port engineLabel engineValue;
in
{
  # StatefulSet rather than Deployment purely for the weights volume: replicas
  # land on DIFFERENT nodes (each takes that node's single amd.com/gpu
  # exclusively), and a ReadWriteOnce Longhorn volume attaches to one node at a
  # time — so a shared `persistence` claim caps this at one replica by
  # construction. A volumeClaimTemplate gives each replica its own model cache.
  type = "statefulset";

  inherit (inst) replicas;

  # RollingUpdate is safe here in a way a Deployment's is not: a StatefulSet
  # terminates the outgoing pod and waits for it to go away before scheduling
  # its replacement, so the GPU is free by the time the new pod needs it.
  strategy = "RollingUpdate";

  # No ordering relationship between replicas — independent servers behind one
  # Service, not a quorum. Parallel so first boot loads them at once.
  statefulset.podManagementPolicy = "Parallel";

  # Re-downloadable weights: single-replica storage on purpose.
  statefulset.volumeClaimTemplates = [
    {
      name = "models";
      accessMode = "ReadWriteOnce";
      size = "30Gi";
      storageClass = "longhorn-single";
      globalMounts = [ { path = "/models"; } ];
    }
  ];

  pod.labels.${engineLabel} = engineValue;

  containers.main = {
    image = {
      inherit (images."ggml-org/llama.cpp") repository digest;
    };

    # llama-server takes its whole configuration from LLAMA_ARG_*, so no args
    # are needed; the image's entrypoint is the server and it presets
    # LLAMA_ARG_HOST=0.0.0.0.
    env = {
      LLAMA_ARG_HF_REPO = inst.model;
      LLAMA_ARG_ALIAS = inst.modelAlias;
      # -hf pulls a multimodal projector alongside the weights whenever the
      # repo has one: an extra download, held in RAM, for a text-only workload.
      # No-op on instances whose repo ships no projector.
      LLAMA_ARG_MMPROJ_AUTO = "0";
      LLAMA_ARG_PORT = toString port;
      # KV is UNIFIED — one pool of LLAMA_ARG_CTX_SIZE cells shared by every
      # slot, each of which is nonetheless told it has the whole thing. Both
      # are pinned so the pool always covers the slots drawing on it (see
      # parallelSlots in instances.nix).
      LLAMA_ARG_N_PARALLEL = toString inst.parallelSlots;
      LLAMA_ARG_CTX_SIZE = toString (inst.contextSize * inst.parallelSlots);
      LLAMA_ARG_N_GPU_LAYERS = toString inst.gpuLayers;
      # Weights land on the PVC instead of the container filesystem, so a
      # restart does not re-download tens of GB.
      LLAMA_CACHE = "/models";
      # /metrics — tokens/sec and prompt-eval timings come from here.
      LLAMA_ARG_ENDPOINT_METRICS = "1";
    };

    probes = import ./_llama-cpp-probes.nix port;

    ports = [
      {
        name = "http";
        containerPort = port;
      }
    ];

    # amd.com/gpu must appear identically in requests and limits; k8s forbids
    # overcommitting extended resources.
    resources = {
      requests = {
        cpu = "500m";
        memory = "2Gi";
        "amd.com/gpu" = 1;
      };
      limits = {
        cpu = "6000m";
        memory = inst.memoryLimit;
        "amd.com/gpu" = 1;
      };
    };
  };
}
