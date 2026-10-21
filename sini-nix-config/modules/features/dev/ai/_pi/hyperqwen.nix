# Keyed: the key is an agenix secret (services.ai.hyperqwen-client), read at runtime so it
# never enters the store. pi and omp share the provider.
config: {
  name = "HyperQwen (cortex-cuda)";
  baseUrl = "http://10.9.2.2:18020/v1";
  api = "openai-completions";
  apiKey = "!cat ${config.age.secrets.hyperqwen-api-key.path}";
  compat = {
    supportsDeveloperRole = true;
    # Its prepare step maps high/max to xhigh, so every pi level is accepted.
    supportsReasoningEffort = true;
  };
  models = [
    {
      id = "qwen3.8-27b";
      name = "Qwen 3.8 27B (HyperQwen vLLM, CTX=long)";
      reasoning = true;
      contextWindow = 150000;
      maxTokens = 32768;
    }
  ];
}
