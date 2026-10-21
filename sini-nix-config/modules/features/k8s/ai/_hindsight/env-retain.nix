# Per-operation override for retain, emitted ONLY when it
# actually differs from the default. Pointing both at one
# instance and still emitting these would be four env vars
# restating the global config — and a reader would reasonably
# infer a split that isn't there.
{ llm }:
{
  HINDSIGHT_API_RETAIN_LLM_PROVIDER = "openai";
  HINDSIGHT_API_RETAIN_LLM_BASE_URL = llm.retainLlm.url;
  HINDSIGHT_API_RETAIN_LLM_MODEL = llm.retainLlm.modelAlias;
  HINDSIGHT_API_RETAIN_LLM_API_KEY = "not-needed";

  # ONE. Not derived like the read path's cap, because an external
  # endpoint's capacity is not ours to compute — it is stated at the
  # externalLlms entry, and ninfer's says maxConcurrency=1 with hermes
  # as primary tenant. Measured besides: ninfer batches DECODE well but
  # SERIALIZES PREFILL (four 30K-token prompts finishing 72s apart),
  # and retain is prefill-bound — 5252 prompt tokens against 1520 out.
  # So concurrency above 1 inflates each request's wall time without
  # adding throughput, and every extra second is spent inside the
  # timeout.
  #
  # ★★★ ninfer CANNOT SERVE RETAIN. Trialled and REVERTED 2026-09-02:
  #     HTTP 400 response_format_not_supported —
  #     "only response_format {type:text} is supported"
  # Fact extraction requests STRUCTURED OUTPUT; ninfer accepts text only,
  # so every retain failed 4/4 attempts. This is a capability gap, not a
  # tuning one — no timeout, concurrency or token budget reaches it.
  # ★ THE TRIAL THAT SAID OTHERWISE MEASURED THE WRONG PREDICATE. A hand-
  # built chat completion with the same mission and a real 12000-char chunk
  # returned in 13.6s at 445 tok/s against llama-cpp's 422.9s — true, and
  # irrelevant, because it omitted the response_format hindsight sends.
  # A probe must issue the REQUEST SHAPE THE CALLER USES, not the prompt.
  # ⇒ Re-test with a response_format request before proposing this again.
  #
  # ★ THE BACKFILL ERA IS OVER (2026-09-02) — retain is back in-cluster and
  # this whole block is DORMANT: it emits only while retainLlmInstance differs
  # from defaultLlmInstance. Kept because the era will recur, and because what
  # it records is the reason the split was worth making. The corpus it built:
  # 101 sessions across two hosts, 239 law/ADR documents re-extracted, 88
  # handoff revisions, ~6100 episode facts at 98.4% labelled, zero failures.
  #
  # ⇒ RESOLVED by cortex-cuda running llama-cpp with the SAME MODEL on
  # :8080 beside ninfer on :8081. llama-cpp constrains decoding to a
  # schema, so json_schema and json_object both return 200 (measured
  # 2026-09-02, 1.8s for 4563 prompt tokens). retainLlmInstance points
  # there; the model is unchanged, so this moves WHERE extraction runs
  # and not what the corpus was extracted by.
  #
  # Concurrency 2, not 1: this is llama-cpp at its default
  # parallelSlots, not ninfer's stated maxConcurrency=1.
  #
  # Retain runs OFF-CLUSTER on a workstation GPU, which is the
  # point: the write path stops sharing a queue with recall. Measured
  # 2026-09-01 on identical work — one real 12000-char chunk under the
  # live episode mission:
  #     llama-cpp gpt-oss-20b   422.859s   (7642 in / 67 out)
  #     ninfer    qwen3.8-27b    13.6s     (5252 in / 800 out, 445 tok/s)
  # ★ THE STANDING CAVEAT AT THE externalLlms ENTRY STILL APPLIES: this
  # is a dev workstation that queues behind interactive work and stops
  # when it reboots — "suitable for batch corpus work, not the live
  # path". archiveHook makes SessionEnd a live path, so that risk is
  # accepted rather than absent. It is bounded: the archiver fails OPEN
  # and hindsight-backfill's completeness check republishes anything
  # left short. Revisit when the backfill era ends.
  HINDSIGHT_API_RETAIN_LLM_MAX_CONCURRENT = "2";
}
