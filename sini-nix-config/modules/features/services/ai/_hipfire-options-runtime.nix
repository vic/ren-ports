# hipfire settings options, part 2: serving and sampling (see hipfire.nix).
{ lib, types, ... }:
{
  port = lib.mkOption {
    type = types.port;
    default = 11435;
    description = "Port for the OpenAI-compatible API server (upstream default; llama-cpp holds 8080, ollama 11434, ninfer 8081).";
  };

  openFirewall = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Open the API port in the firewall so clients on the LAN/bridge can reach the daemon.";
  };

  maxSeq = lib.mkOption {
    type = lib.types.int;
    default = 32768;
    description = ''
      KV cache physical capacity in tokens (memory.max_seq). The Qwen3.8
      27B models carry a native 262K context; the ceiling actually
      reachable is VRAM-derived — the daemon loads with less if the pool
      cannot hold more. Raise for longer prompts once measured headroom
      allows.
    '';
  };

  maxTokens = lib.mkOption {
    type = lib.types.int;
    default = 32768;
    description = "Per-request output cap applied when a request omits one (generation.max_tokens).";
  };

  temperature = lib.mkOption {
    type = lib.types.float;
    default = 0.3;
    description = "Sampling temperature (upstream default).";
  };

  topP = lib.mkOption {
    type = lib.types.float;
    default = 0.8;
    description = "Nucleus sampling threshold (upstream default).";
  };

  repeatPenalty = lib.mkOption {
    type = lib.types.float;
    default = 1.05;
    description = "Repetition penalty. Keep conservative — upstream notes 1.3+ causes MQ4 gibberish at low temperature.";
  };

  kvCache = lib.mkOption {
    type = lib.types.str;
    default = "auto";
    example = "asym3";
    description = ''
      KV cache quantization mode: auto / q8 / asym4 / asym3 / asym2 /
      turbo / turbo4 / turbo3 / turbo2. Registry entries also carry a
      per-model default (q8) that applies unless overridden here or in
      `perModelSettings`.
    '';
  };

  dflashMode = lib.mkOption {
    type = lib.types.enum [
      "on"
      "off"
      "auto"
    ];
    default = "off";
    description = ''
      DFlash speculative decode. `auto` engages it when a draft is
      available — set `draftUrl` first. `off` (the default) is
      upstream's stock behavior.
    '';
  };

  idleTimeout = lib.mkOption {
    type = lib.types.int;
    default = 300;
    description = "Seconds before evicting the loaded model from VRAM. 0 = never.";
  };

  extraSettings = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Additional config.toml keys not covered by dedicated options; merged last and can override typed ones.";
  };

  perModelSettings = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = { };
    description = "Per-model overrides written to models.toml, keyed by registry tag.";
  };
}
