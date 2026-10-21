# hipfire settings options, part 1: GPU targets and model artifacts (see hipfire.nix).
{ lib, types, ... }:
{
  gpuTargets = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [
      "gfx1151"
      "gfx1030"
    ];
    description = ''
      GPU architectures to pre-compile kernels for. The upstream module
      asserts this is non-empty — Nix cannot probe hardware at
      evaluation time. Detect yours:
        rocminfo 2>/dev/null | grep -oP 'amdgcn-amd-amdhsa--\K\S+' | sort -u
    '';
  };

  modelUrl = lib.mkOption {
    type = lib.types.str;
    default = "https://huggingface.co/hipfire-models/qwen3.8-27b/resolve/main/qwen3.8-27b.mq4";
    description = ''
      Registry-listed weights artifact fetched into the store. The URL's
      basename must be the exact file name the upstream model registry
      (registry/v1.json) records for `defaultModel` — that is how the
      daemon's tag-to-file resolution finds it in HIPFIRE_MODELS_DIR.
      Qwen3.8 27B MQ4V2 base tier (quality trunk, native 262K context);
      the registry's XT/MQ3/MQ5/MQ6 variants are one-URL swaps.
    '';
  };

  modelHash = lib.mkOption {
    type = lib.types.str;
    default = "sha256-W7VWpsyEA1I0mVwBfJeRqjlRrR6uTPjIFysOrvOZ5Qc=";
    description = ''
      SRI hash of the artifact. Matches the `sha256` published in the
      upstream registry (5bb556a6…9e507), which `hipfire pull` itself
      verifies against.
    '';
  };

  draftUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "https://huggingface.co/hipfire-models/qwen3.8-27b/resolve/main/qwen38-27b-dflash-mq4.hfq";
    description = ''
      Optional DFlash draft artifact (fetched alongside the target and
      available when `dflashMode` is on/auto). Null (the default) ships
      the target alone — `dflashMode` stays off or auto-degrades without
      a draft. If set, its basename must be the registry file name of
      the draft tag that pairs with `defaultModel`.
    '';
  };

  draftHash = lib.mkOption {
    type = lib.types.str;
    default = "";
    example = "sha256-0KdKIyoOIWbYifgj6R4Pv3eNId2WaNfeBVzeywZUAbw=";
    description = "SRI hash of the draft artifact. Required when draftUrl is set.";
  };

  defaultModel = lib.mkOption {
    type = lib.types.str;
    default = "qwen3.8:27b";
    description = ''
      Registry tag pre-warmed on startup (empty = start with no model
      loaded; the daemon then serves on demand). Must be the tag whose
      registry file name is `modelUrl`'s basename, so the pre-warm
      resolves to the store artifact rather than a download.
    '';
  };
}
