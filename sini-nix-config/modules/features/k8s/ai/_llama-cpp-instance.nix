# Option set of one llama-server instance (see instances.nix).
{ lib, name }:
let
  mk = type: default: description: lib.mkOption { inherit type default description; };
in
{
  model = lib.mkOption {
    type = lib.types.str;
    description = ''
      Model for llama-server's -hf (LLAMA_ARG_HF_REPO), as
      `<user>/<repo>[:quant]`. Always name the quant — llama.cpp's
      documented fallback when it is omitted is "the first file in the
      repo", and these repos also carry BF16 shards and speculative
      draft weights.
    '';
  };

  modelAlias = mk lib.types.str name ''
    Name this model answers to over the OpenAI-compatible API
    (LLAMA_ARG_ALIAS). Clients must send exactly this in `model`.
  '';

  contextSize = mk lib.types.ints.positive 131072 ''
    Prompt context in tokens available to ONE request. KV cache
    grows linearly with this and comes out of the same pool as the
    weights, so it is not free — but sizing it below what callers
    actually send fails as a 500 rather than as truncation.

    This is NOT LLAMA_ARG_CTX_SIZE directly — see parallelSlots.
  '';

  replicas = mk lib.types.ints.positive 1 ''
    llama-server pods for this instance, load-balanced by the
    ClusterIP service. Each replica takes a whole node's
    amd.com/gpu exclusively, so this is capped by the number of
    schedulable GPU nodes MINUS whatever other instances hold —
    and a replica over that cap sits Pending forever rather than
    failing at eval.

    Each replica gets its own weights volume (the StatefulSet's
    volumeClaimTemplate), so N replicas cost N copies of the model
    on disk.
  '';

  gpuLayers = mk lib.types.ints.unsigned 99 ''
    Layers to offload to the GPU (LLAMA_ARG_N_GPU_LAYERS). 99 means
    "all"; lower it if the Vulkan device heap cannot hold the model,
    0 for CPU-only. Layers left on the CPU still read from the same
    memory bus, so this costs throughput rather than failing.
  '';

  memoryLimit = mk lib.types.str "24Gi" ''
    Container memory ceiling. The iGPU has no memory of its own —
    weights live in GTT, which is this container's RAM — so this must
    cover the model file plus its KV cache plus compute buffers.

    The KV term is contextSize * parallelSlots, not contextSize.
  '';
}
