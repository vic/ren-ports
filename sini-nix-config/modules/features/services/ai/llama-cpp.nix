# llama-cpp — high-performance long-context LLM inference server (llama-server).
#
# Target single CUDA GPU inside MicroVM. Context is bounded by VRAM: stock
# llama.cpp has no host-RAM streaming for ACTIVE KV, so the ceiling is what the
# card holds at the configured cache-type-k/v (see contextSize).
# TODO: Evaluate Vulkan performance & multi-GPU tensor splitting across hosts later.
#
# Emits llama-cpp-endpoints quirk so consumers (open-webui) can discover instances.
# Files: this (kind), llama-cpp-service.
{ ren, lib, ... }:
let
  models = (import ./_llama-cpp-models.nix).models;
in
{
  ren.kinds.machine.svc-ai-llama-cpp = ren.lib.opt (lib.types.submodule {
    options = {
      model = lib.mkOption {
        type = lib.types.enum (lib.attrNames models);
        default = "gpt-oss-20b";
        description = "The GGUF fetched into the store, by name from the catalogue at the top of this file.";
      };
      parallel = lib.mkOption {
        type = ren.helpers.types.positive;
        default = 1;
        description = "Slots (`--parallel`). With kv-unified they share one ctx-size pool.";
      };
      nCpuMoe = lib.mkOption {
        type = lib.types.nullOr ren.helpers.types.unsigned;
        default = null;
        description = "`--n-cpu-moe`: keep the experts of the first N layers in host RAM. For a MoE that does not fit the card.";
      };
      batchSize = lib.mkOption {
        type = ren.helpers.types.positive;
        default = 2048;
        description = "`--batch-size`.";
      };
      ubatchSize = lib.mkOption {
        type = ren.helpers.types.positive;
        default = 512;
        description = "`--ubatch-size`. Raising it with offloaded experts trades decode for prefill (the r/hermesagent report: 4096 lifted prefill from ~600 to ~1,900 tok/s).";
      };
      modelPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Escape hatch for an out-of-band GGUF on the llama-cpp share. `null`
          (the default) uses the store artifact fetched from `modelUrl`, so the
          model is content-addressed and present by construction rather than
          left to a manual download that the unit would fail without — the same
          arrangement services.ai.ninfer uses.
        '';
      };
      contextSize = lib.mkOption {
        type = lib.types.int;
        # gpt-oss-20b's trained window, and its ceiling: max_position_embeddings
        # is 131,072, reached by YaRN at factor 32 over a 4,096 original. The
        # previous 262,144 was Qwen3.8-27B's window carried over unchanged, i.e.
        # double what this model was trained for — asking for it does not fail,
        # it extrapolates, which is the silent-degradation shape rather than a
        # loud one.
        default = 131072;
        description = "Maximum context window size in tokens";
      };
      cacheRamMB = lib.mkOption {
        type = lib.types.int;
        default = 49152;
        description = ''
          `--cache-ram`: host budget for llama.cpp's PROMPT cache (saved slot
          state), not a spillover path for active KV. It buys prompt reuse
          across turns, which is what an agent loop needs; it does not raise
          the context ceiling.
        '';
      };
      kvCacheType = lib.mkOption {
        type = lib.types.str;
        default = "f16";
        description = ''
          `--cache-type-k`/`-v`. Unquantized by default because gpt-oss-20b
          does not need the compression: only 12 of its 24 layers use full
          attention (the rest slide at window 128) over 8 KV heads x 64 dim, so
          the whole 131,072-token cache is small.

          Measured on cortex-cuda's 24,564 MiB card at ctx-size 131072, model
          resident: f16 sits at 15,660 MiB (8,904 MiB free), q8_0 at 14,410 MiB.
          The previous q4_0 was carried over from the Qwen3.8-27B profile, where
          the cache genuinely was the binding constraint — here it spent
          accuracy to reclaim headroom that was never contended.
        '';
      };
    };
  }) { };
}
