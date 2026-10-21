# NInfer-3090 (https://github.com/Don-Chad/ninfer-3090):
# SM86-only CUDA inference engine for Qwen3.8-27B, serving OpenAI Chat /
# Responses and Anthropic Messages from one resident engine.
#
# Targets the RTX 3090 Ti (10de:2203, GA102, sm_86) passed through to the
# cortex-cuda guest. The upstream flake pins its own nixpkgs (CUDA 12.9 +
# gcc13) because nvcc 12.9 rejects the gcc15 default stdenv, so the package is
# taken from that flake rather than rebuilt against the guest's channel.
#
# Weights, KV pool and CUDA graphs do not fit alongside another engine on one
# 24 GB card, so the unit conflicts with llama-cpp/ollama and does NOT
# auto-start: `systemctl start ninfer` swaps the resident engine, and starting
# llama-cpp swaps it back.
#
# Compatible-prefix caching is on by default (`--no-prefix-reuse` turns it
# off) and is deliberately left alone: every consumer here is an agent loop
# that resends a growing conversation each turn, so cached-prefix TTFT
# dominates decode rate for this workload.
#
# Emits ninfer-endpoints so pi/hermes derive endpoint AND model identity
# instead of hardcoding the guest address.
# Files: this (kind), _ninfer-options-*, _ninfer-models, ninfer-channels, ninfer-service, ninfer-firewall.
{ ren, lib, inputs, ... }:
let
  inherit (import ./_ninfer-models.nix) models;
  args = { inherit lib models; inherit (ren.helpers) types; };
in
{
  ren.kinds.machine.svc-ai-ninfer = ren.lib.opt (lib.types.submodule {
    options = inputs.nixpkgs.lib.mergeAttrsList (
      map (f: import f args) [
        ./_ninfer-options-model.nix
        ./_ninfer-options-kv.nix
        ./_ninfer-options-engine.nix
        ./_ninfer-options-clients.nix
      ]
    );
  }) { };
}
