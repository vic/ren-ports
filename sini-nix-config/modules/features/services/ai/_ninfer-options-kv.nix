# ninfer settings options, KV pool and admission (see ninfer.nix).
{ lib, types, ... }:
{
  kvCapacity = lib.mkOption {
    type = lib.types.str;
    default = "150912";
    description = ''
      Shared KV pool sizing (`--kv-capacity`). Must equal maxContext at
      concurrency 1; `auto` instead sizes the pool from VRAM left after
      weights while holding back 1 GiB of headroom.

      We reserve explicitly rather than using `auto` so the pool is a
      declared quantity instead of a function of whatever VRAM happens to
      be free at start. At the current maxContext the two agree on size, so
      the 1 GiB `auto` withholds simply stays free — and that GiB is the
      tolerance for any other GPU consumer on this VM.

      ninfer reserves its complete runtime layout at STARTUP, so free VRAM
      is unchanged between idle and a full-context prefill: if it starts,
      it runs. Spending the GiB to chase the allocation boundary is what
      the previous 238720/rk8v4 profile did, and it left 75 MiB physically
      free — no room for a second model, `--vision`, or a higher
      maxConcurrency. Set this to `auto` before adding one.
    '';
  };
  kvDtype = lib.mkOption {
    type = lib.types.enum [
      "bf16"
      "int8"
      "rk8v4"
    ];
    default = "int8";
    description = ''
      KV-cache storage, and the main context/quality dial.

      int8 is upstream's default and their stated "recommended quality
      setting". rk8v4 (RotorQuant: 8-bit keys, 4-bit values) is flagged
      EXPERIMENTAL and opt-in, with the explicit instruction not to use it
      as the default for correctness-sensitive work. Every consumer of this
      endpoint is an agent that edits code, which is correctness-sensitive
      work, so int8 it is.

      What rk8v4 buys, measured here: +31.7% context (150912 -> 198720) for
      -4% decode (96.2 -> 92.3 tok/s) and no prefill cost (1121 -> 1123
      tok/s), reproducing upstream's ~32% context and ~2% decode figures.

      What it costs is unquantified at length. Upstream's only matched
      quality test ran at 4K and the rk8v4 answer introduced a faulty
      nested-rollback design the int8 answer avoided; nobody has
      characterised 4-bit values at 150K+. Raise it only together with
      maxContext, and only for work where a wrong answer is cheap.
    '';
  };
  maxConcurrency = lib.mkOption {
    type = (types.between 1 8);
    default = 1;
    description = "Concurrently admitted requests (`--max-concurrency`). 1 gives the lowest latency and the largest per-request KV entitlement.";
  };
  pendingTimeoutMs = lib.mkOption {
    type = lib.types.int;
    default = 600000;
    description = ''
      How long a request may wait for an admission slot
      (`--pending-timeout-ms`) before the server answers 503
      `request_queue_timeout`.

      The engine default is 30s, which is shorter than a single large
      prefill, so it bounds agent fan-out well before maxConcurrency does.
      Measured on this artifact: four clients each sending ~39.4K tokens
      got one admission (37.7s) and three expiries at 30.4s. Requests queue
      behind prefill, so the deadline has to clear the slowest prefill in
      flight rather than the decode. Ten minutes hands the policy back to
      each client's own HTTP timeout, which is where it belongs.
    '';
  };
}
