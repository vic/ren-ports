# Hindsight setting, a cluster field: key into the k8s-ai-llama-cpp-settings-instances
# field (or externalLlms) serving the default LLM for every operation without its own
# override. Points at instances by KEY rather than by URL or model name, so the model
# identity lives in exactly one place and changing a model there carries here.
{ ren, lib, ... }:
{
  # Everything except retain: reflect, consolidation, verification. gpt-oss-20b
  # is rank 2 of 21 on upstream's reflect leaderboard (86.3 against the leader's
  # 86.6, and the leader is gpt-oss-120b which will not fit here). No Qwen model
  # appears on that board at all.
  ren.kinds.cluster.k8s-ai-hindsight-settings-defaultLlmInstance = ren.lib.opt lib.types.str "gpt-oss";
}
