# hipfire (https://github.com/warpfront/hipfire):
# RDNA/CDNA-native LLM inference engine in Rust, serving an OpenAI-compatible
# API. Not a wrapper around llama.cpp/candle/vLLM: its kernel family,
# HFQ/MagnumQuant quant formats and speculative-decode paths are original
# upstream work (see its PRIOR-ART.md).
#
# Engine, packaging and service all come from upstream's own flake, which
# ships:
#   - nixosModules.default: the services.hipfire module — config.toml and
#     models.toml generation, systemd units (a boot-time kernel
#     pre-compile step plus the daemon), ROCm ICD registration and the
#     dedicated service user.
#   - overlays.default: injects rocmPackages built from the flake's pinned
#     nixpkgs (ROCm 7.x). Mandatory: the ROCm 6.4.3 that nixos-25.11-era
#     nixpkgs ship segfaults libamdhip64 on gfx1151 (Strix Halo) during
#     weight upload. The overlay flows into both the package builds and
#     the module's LD_LIBRARY_PATH / ICD wiring, so host and runtime share
#     one ROCm instance.
#
# We follow latest upstream: the input tracks `master`. Upstream's
# flake.lock pins its own nixpkgs + rust-overlay, so `nix flake update
# hipfire` moves the engine forward reproducibly without dragging the
# host's nixpkgs along.
#
# Model acquisition is store-driven: the registry-listed weights are
# fetched content-addressed from HuggingFace and composed into an immutable
# store directory that the daemon reads as HIPFIRE_MODELS_DIR. The daemon's
# resolver uses a local file as-is and never re-downloads, and nothing in
# this aspect mutates the local system at boot — no `hipfire pull` step, no
# unit race, and the model is present by construction. Ephemeral state
# (kernel JIT cache, daemon state) is recreated by upstream's
# hipfire-setup/hipfire-precompile units on every boot, which is the design
# under a wiped /var.
#
# Emits hipfire-endpoints so pi/hermes derive endpoint AND model identity
# instead of hardcoding the host address.
# Files: this (kind, channels), _hipfire-options-{model,runtime,service}, hipfire-service.
{
  ren,
  inputs,
  lib,
  ...
}:
{
  ren.kinds.machine.svc-ai-hipfire = ren.lib.opt (lib.types.submodule {
    options =
      import ./_hipfire-options-model.nix { inherit lib; inherit (ren.helpers) types; }
      // import ./_hipfire-options-runtime.nix { inherit lib; inherit (ren.helpers) types; }
      // import ./_hipfire-options-service.nix { inherit lib; inherit (ren.helpers) types; };
  }) { };

  ren.aspects.svc-ai-hipfire = {
    flake-inputs.hipfire.url = "github:warpfront/hipfire";

    # Upstream's rocmPackages/hipfire overlay must be part of this host's
    # package set: the upstream module's defaults (pkgs.hipfire,
    # pkgs.rocmPackages.* in LD_LIBRARY_PATH and ICD registration) resolve
    # against it.
    nixpkgs-overlays = [ inputs.hipfire.overlays.default ];

    # Endpoint AND model identity: consumers need the exact model tag plus
    # the context/output bounds, not just an address.
    hipfire-endpoints =
      { host, ... }:
      let
        cfg = host.svc-ai-hipfire;
      in
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        inherit (cfg)
          port
          maxSeq
          maxTokens
          ;
        modelId = cfg.defaultModel;
        maxContext = cfg.maxSeq;
      };
  };
}
