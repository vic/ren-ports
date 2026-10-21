# Concurrency caps derived from what actually serves the default LLM.
{ llm }:
{
  # ★★★ MAKE BACKPRESSURE LAND WHERE WAITING IS FREE.
  # Work can wait in three places and only two of them are free:
  #   1. the DURABLE TASK QUEUE in postgres — observable, survives
  #      a restart, no clock running. Bounded by WORKER_MAX_SLOTS.
  #   2. the CLIENT SEMAPHORE — a call blocks before the request is
  #      issued, so no timeout is ticking. Bounded by LLM_MAX_CONCURRENT.
  #   3. llama-server's own SOCKET QUEUE — a request that is waiting
  #      for a slot is already inside its timeout. This one is NOT free.
  #
  # Measured 2026-09-01, all three unset and therefore at upstream
  # defaults: WORKER_MAX_SLOTS 10 (8 shared + 2 reserved) and
  # LLM_MAX_CONCURRENT 32, against a real serving capacity of
  # N_PARALLEL 2 x 3 replicas = 6. A backfill put 124 tasks in the
  # queue, 8 claimed slots at once, the surplus queued in (3), each
  # burned the 120s LLM_TIMEOUT while waiting, failed with
  # APITimeoutError, and retried — which re-queued them. Observed:
  # `slots=9/10 | shared=8/8(avail=0)`, one call at 422.859s, a
  # consolidation stuck 3298s at attempt 3/4, 5 failed retains.
  # That is a retry storm, not a queue draining.
  #
  # So the cap is DERIVED from what actually serves, and the surplus
  # is pushed back into (1) and (2) where it waits for free.
  HINDSIGHT_API_LLM_MAX_CONCURRENT = toString llm.defaultLlm.slots;

  # In-flight tasks per worker. Held at the serving capacity for the
  # same reason: a claimed slot whose LLM call cannot be served is a
  # task holding a slot AND a socket, while an unclaimed task costs a
  # postgres row. Reserved consolidation slots come out of this total,
  # so this is the ceiling on everything, not just retain.
  HINDSIGHT_API_WORKER_MAX_SLOTS = toString llm.defaultLlm.slots;

  # A slow call must COMPLETE, not fail and retry. Upstream default is
  # 120s; a real retain_extract_facts call measured 422.859s on this
  # hardware at 7642 input tokens. With concurrency now matched to
  # capacity a request should not queue at llama-server at all, but a
  # long chunk on a cold slot still exceeds two minutes, and failing
  # it converts one slow extraction into four (WORKER_MAX_RETRIES=3).
  HINDSIGHT_API_LLM_TIMEOUT = "900";
}
