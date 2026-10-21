# ninfer settings options, model, port, context (see ninfer.nix).
{ lib, types, models, ... }:
{
  model = lib.mkOption {
    type = lib.types.enum (lib.attrNames models);
    default = "qwen3.8-27b";
    description = ''
      The .ninfer artifact fetched into the store, by name from the
      catalogue at the top of this file (URL and SRI hash per entry).
    '';
  };
  modelPath = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Escape hatch for an out-of-band artifact on the ninfer share. `null`
      (the default) uses the store artifact of `model`, so the
      model is content-addressed and present by construction rather than
      left to a manual download that the unit would fail without.
    '';
  };
  modelId = lib.mkOption {
    type = lib.types.str;
    default = "qwen3.8-27b";
    description = ''
      Public model alias (`--model-id`). NInfer rejects a request whose
      `model` field does not equal this string, so it is emitted on the
      ninfer-endpoints quirk and consumers must send exactly this value.
    '';
  };
  port = lib.mkOption {
    type = types.port;
    default = 8081;
    description = "Listen port. Deliberately not llama-cpp's 8080 so both stay addressable in client config while alternating on the GPU.";
  };
  maxContext = lib.mkOption {
    type = lib.types.int;
    default = 150912; # 2358 pages x 64 tokens
    description = ''
      Per-sequence logical context ceiling (`--max-context`), measured on
      a 24 GB card under every other default here. This value is
      kvDtype-DEPENDENT; the measured ceilings on this hardware are, with
      `--kv-capacity auto` (i.e. holding back 1 GiB of headroom):

        int8  + MTP3 + graphs   150912
        rk8v4 + MTP3 + graphs   198720
        int8,   no MTP/graphs   186944
        rk8v4,  no MTP/graphs   247040

      Note rk8v4 WITH speculation beats int8 WITHOUT it, so buying context
      by disabling MTP/CUDA graphs is never the right trade here.

      The default is the int8 + MTP3 + graphs row. kvCapacity reserves
      that size EXPLICITLY rather than via `auto`, so the 1 GiB `auto`
      would hold back stays physically free instead: this is the measured
      ceiling carrying a full GiB of tolerance, not a knife-edge.

      A larger number is reachable (238720 at rk8v4, which started and ran
      a real 154,719-token prefill) but it is an ALLOCATION boundary, not a
      quality one — upstream says of their comparable figure that it is
      "an allocation plus short-execution boundary, not a full 226K prefill
      quality claim". Nothing has been validated for OUTPUT QUALITY above
      154,719, and a context whose answers are wrong is not context.
      Keep this equal to kvCapacity.

      Sizing is a deterministic page calculation rather than allocation
      probing, so these boundaries are reproducible rather than lucky.
      Raising this value without also raising kvDtype makes startup fail
      loudly (the KV pool cannot hold one full sequence).
    '';
  };
}
