# ninfer settings options, speculation, thinking, start (see ninfer.nix).
{ lib, types, ... }:
{
  draftTokens = lib.mkOption {
    type = (types.between 0 5);
    default = 3;
    description = ''
      MTP speculative draft window. 0 disables speculative decoding.
      5 is the engine's hard cap for `--spec mtp`; `--spec dflash` would
      take up to 15, but the pinned Qwen3.8-27B artifact carries no DFlash
      weights (upstream ships those only in the Qwen3.6-35B-A3B v2
      container, which is not the measured 3090 memory profile).

      3 was not a free choice at the former 238720/rk8v4 profile: raising
      it to 5 grew the Engine runtime reservation past the explicit KV pool
      and startup was REJECTED. The current profile leaves a spare GiB, so
      5 may now fit — unmeasured. If you widen it, confirm startup rather
      than assuming, and lower maxContext/kvCapacity if it is refused.
    '';
  };
  prefillChunk = lib.mkOption {
    type = lib.types.int;
    default = 1024;
    description = ''
      Text-prefill chunk size (`--prefill-chunk`). Forced by the explicit
      KV reservation at the former 238720/rk8v4 profile, where 2048 and
      4096 both failed to start — same runtime-reservation rejection as a
      wider draft window. The current profile has a spare GiB, so they may
      now fit; unmeasured.

      Measured to cost nothing: at a context where 4096 does fit, it
      prefills 15,523 tokens in 13.66s against 13.84s for 1024 (~1%,
      noise). Not a lever worth reclaiming context for.
    '';
  };
  maxTokens = lib.mkOption {
    type = lib.types.int;
    default = 32768;
    description = "Output limit applied when a request omits one (`--default-max-tokens`).";
  };
  thinkingBudget = lib.mkOption {
    type = lib.types.nullOr types.positive;
    default = null;
    description = ''
      `--default-thinking-budget`: cap thinking for every thinking-enabled request, then
      close `</think>` and continue to content or tool calls. Bounds reasoning server-side
      for a template that rejects `reasoning_effort` (Qwen3.6). null = unbounded.
    '';
  };
  preserveThinking = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Keep reasoning from closed assistant turns in later prompts (`--preserve-thinking`).";
  };
  autoStart = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Start at boot. Off by default because the unit conflicts with
      llama-cpp/ollama over the single GPU — leaving it off keeps the
      incumbent engine resident and makes ninfer an explicit
      `systemctl start ninfer` swap.
    '';
  };
  alsoAdmitPorts = lib.mkOption {
    type = lib.types.listOf types.port;
    default = [ ];
    description = ''
      Other ports on this host admitted to exactly ninfer's sources: another engine
      serving the same consumers (e.g. services.ai.hyperqwen) while ninfer stands by.
    '';
  };
}
