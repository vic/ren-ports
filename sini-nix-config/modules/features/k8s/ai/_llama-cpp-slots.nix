# The parallelSlots option of a llama-server instance (see instances.nix).
#
# The defect this option exists to prevent, measured 2026-08-31:
# llama-server was started with LLAMA_ARG_CTX_SIZE=16384 and no
# -np, and chose `n_slots = 4, n_ctx_slot = 16384,
# kv_unified = 'true'` on its own. Under a unified KV cache the
# 16384 cells are ONE pool shared by all four slots, while each
# slot is told it has the full 16384 — a 4:1 oversubscription that
# cannot be seen from the setting that caused it.
#
# It does not fail cleanly. The server logs "decode: failed to find
# free space in the KV cache, retrying with smaller batch size" and
# walks prefill down 1024 -> 512 -> ... -> 8, silently. During the
# den-law corpus ingest that fired 305 times in 30 minutes on the
# serving instance against 0 on the idle one.
#
# So contextSize is per-request and the aspect multiplies. The
# coupling is arithmetic in one place instead of an implicit
# relationship between one setting and a default chosen elsewhere.
{ lib }:
lib.mkOption {
  type = lib.types.ints.positive;
  default = 2;
  description = ''
    Concurrent request slots (LLAMA_ARG_N_PARALLEL). Total KV pool
    is contextSize * parallelSlots, so each slot gets a real
    contextSize rather than competing for a shared one.

    That product is the whole budget, and how it is SLICED is free:
    a 262144-token pool costs the same as 1x262144, 2x131072 or
    4x65536. Only the per-request ceiling and the concurrency move.
    It is sliced 2x131072 here because the observed failures were
    context failures, not queueing — hindsight sends whole
    documents, and in verbatim mode the model must reproduce its
    input, so one request costs roughly twice the document.

    Slots are the wrong axis to buy throughput on anyway: measured
    aggregate on a 780M was 23.5 tok/s at 1 concurrent request,
    32.4 at 2 and 40.5 at 4 — 1.72x for 4x the load, while
    per-stream fell 23.5 -> 10.1. Decode is bandwidth-bound and
    this is a fine-grained MoE, so batching amortizes weight reads
    poorly (different sequences activate different experts). Add
    REPLICAS on other nodes instead: each brings its own memory bus
    and scales ~linearly at full per-stream rate.
  '';
}
