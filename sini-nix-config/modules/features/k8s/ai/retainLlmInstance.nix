# Hindsight setting, a cluster field: key serving the retain (fact-extraction)
# path, via HINDSIGHT_API_RETAIN_LLM_*. When equal to the default instance the
# per-operation override is omitted entirely.
{ ren, lib, ... }:
{
  # Same instance as the default for now, which collapses the split: when this
  # equals defaultLlmInstance the aspect emits no HINDSIGHT_API_RETAIN_LLM_*
  # at all and every operation runs on one model.
  #
  # The leaderboard argues for Qwen3.6 35B-A3B here — it leads the open-weight
  # retain field at quality 59.5 (49%) against gpt-oss 20B's 56.3 (48%). First
  # contact on this hardware did not bear that out: extracting from a 136-char
  # document took Qwen 104s and 2121 output tokens for ONE memory unit, where
  # gpt-oss took 179 output tokens for TWO from a comparable input. Not hidden
  # reasoning — thoughts_tokens was 0 and raw completions showed empty <think>
  # blocks — just verbosity that bought nothing.
  #
  # Two documents is not a sample, and the leaderboard is a real measurement
  # against a real benchmark, so this is provisional rather than a refutation.
  # Set this to "qwen" to restore the split; the instance stays deployed.
  ren.kinds.cluster.k8s-ai-hindsight-settings-retainLlmInstance = ren.lib.opt lib.types.str "gpt-oss";
}
