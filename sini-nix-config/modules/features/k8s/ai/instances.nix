# Settings for the cluster llama-cpp aspect (k8s-ai-llama-cpp). Set per cluster
# via `ren.cluster.<name>.k8s-ai-llama-cpp-settings-instances`.
#
# Distinct from `svc-ai-llama-cpp`, the NixOS aspect that runs llama-server
# on a host against a discrete CUDA GPU. Same engine, different substrate.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  instT = lib.types.submodule (
    { name, ... }:
    {
      options = import ./_llama-cpp-instance.nix { inherit lib name; } // {
        parallelSlots = import ./_llama-cpp-slots.nix { inherit lib; };
      };
    }
  );
in
{
  # One llama-server per entry. A llama-server process serves exactly one model,
  # and each node advertises exactly one amd.com/gpu which the device plugin
  # allocates exclusively — so an entry here costs a whole node's GPU, and the
  # number of entries cannot exceed the number of schedulable GPU nodes.
  #
  # Each entry becomes a Deployment/Service pair `llama-cpp-<key>` in the `ai`
  # namespace, reachable at `http://llama-cpp-<key>.ai.svc:8080/v1`.
  #
  # ONE model, replicated across every GPU node, rather than two models on one
  # node each. gpt-oss 20B is rank 2 of 21 on upstream's reflect board (86.3,
  # 0.3 behind gpt-oss-120b, which will not fit here).
  #
  # Qwen3.6 35B-A3B was the second instance and held a whole node for the
  # retain path. It is dropped: nothing routed to it (both defaultLlmInstance
  # and retainLlmInstance resolved to gpt-oss); extracting from a 136-char
  # document took 104s and 2121 output tokens for ONE memory unit where gpt-oss
  # produced TWO from 179 (verbosity, not hidden reasoning); and ninfer (see
  # externalLlms) serves a stronger retain model at ~68 tok/s against this
  # hardware's 23.5. To restore it, add back alongside gpt-oss, drop replicas to
  # match the GPU budget — the entry was:
  #
  #   qwen = {
  #     model = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M";
  #     modelAlias = "qwen3.6-35b-a3b";
  #     memoryLimit = "40Gi";   # 22.1 GB weights + ~5.2 GB KV + buffers
  #   };
  #
  # It also needs its `llama-cpp-qwen-internal` LoadBalancer address back in
  # the cluster's kubernetes-loadbalancers assignments, or eval fails.
  ren.kinds.cluster.k8s-ai-llama-cpp-settings-instances = opt (lib.types.attrsOf instT) {
    "gpt-oss" = {
      model = "ggml-org/gpt-oss-20b-GGUF:MXFP4";
      modelAlias = "gpt-oss-20b";

      # 131072 is this model's NATIVE context — asking for more buys no usable
      # context without RoPE scaling. Sliced 2x131072, so the pool is 262144.
      #
      # 12 GB of weights + ~6 GB KV for that pool + compute buffers. The APU
      # can afford it precisely because it is a UMA part: 62 GB addressable
      # against the 24 GB of the discrete card.
      memoryLimit = "40Gi";

      # One per GPU node. Sole instance, so the whole budget is available:
      # three separate memory buses at full per-stream rate (see parallelSlots).
      replicas = 3;
    };
  };
}
