# Core env of the dataplane container: identity, database, LLM provider.
{ shared, llm }:
{
  HINDSIGHT_API_HOST = "0.0.0.0";
  HINDSIGHT_API_PORT = toString shared.port;
  HINDSIGHT_API_LOG_LEVEL = "info";

  # A worker claims operations under this id and holds them in
  # 'processing' until it reports back. Left unset it defaults
  # to the hostname — the pod name — which churns on every
  # restart, so in-flight work is orphaned under an identity
  # that no longer exists and cannot be addressed afterwards.
  #
  # Pinning it does NOT make recovery automatic: upstream has
  # no startup reclaim (decommission-worker exists only in the
  # admin CLI, and its documented use case is "if a worker
  # crashed while processing tasks"). What pinning buys is a
  # KNOWN name to release, which the init container does.
  HINDSIGHT_API_WORKER_ID = "hindsight";

  HINDSIGHT_API_DATABASE_URL.valueFrom.secretKeyRef = {
    name = "hindsight-pg-dsn";
    key = "url";
  };
  # Upstream's default, stated explicitly because hindsight-pg
  # provisions to match it (CREATE EXTENSION vector).
  HINDSIGHT_API_VECTOR_EXTENSION = "pgvector";

  # `openai`, not `llamacpp`: upstream's in-process llamacpp
  # provider needs llama-cpp-python, which the published image
  # deliberately omits (it fails with ModuleNotFoundError).
  # Talking to a llama-server over its OpenAI-compatible API is
  # the supported shape, and upstream's own local-llm compose
  # example does exactly this.
  HINDSIGHT_API_LLM_PROVIDER = "openai";
  HINDSIGHT_API_LLM_BASE_URL = llm.defaultLlm.url;
  HINDSIGHT_API_LLM_MODEL = llm.defaultLlm.modelAlias;
  # The openai provider requires this populated even when the
  # backend ignores it; llama-server runs with no API key set.
  # Upstream's own example uses the literal "not-needed".
  HINDSIGHT_API_LLM_API_KEY = "not-needed";

  # Not a tuning preference — a 15.5-point swing on upstream's
  # own retain leaderboard (v0.9.2, the version pinned here):
  # gpt-oss 20B at LOW ranks 4th at 57.8 and 5.1s end to end,
  # the same model at MEDIUM ranks 14th at 42.3 and 55.2s.
  # Leaving this unset sends no reasoning parameter at all, and
  # gpt-oss then runs at its own default — which is medium.
  HINDSIGHT_API_LLM_REASONING_EFFORT = "low";

  # Upstream default is false: a retain that hit extraction
  # errors is reported 'completed' and the dropped facts are
  # silently unreachable by recall. That is precisely the
  # failure this deployment exists to stop happening to the
  # law corpus, so failures are made loud.
  HINDSIGHT_API_FAIL_ON_EXTRACTION_ERRORS = "true";
}
