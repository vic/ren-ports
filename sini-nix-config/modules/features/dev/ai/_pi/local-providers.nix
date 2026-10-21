# pi: keyless local providers (ollama, llama.cpp) on cortex-cuda.
{
  ollama = {
    name = "Ollama (cortex-cuda)";
    baseUrl = "http://10.9.2.2:11434/v1";
    api = "openai-completions";
    apiKey = "ollama";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = "qwen3.8:27b";
        name = "Qwen 3.8 27B (Ollama)";
        reasoning = true;
        contextWindow = 262144;
        maxTokens = 16384;
      }
    ];
  };
  llama-cpp = {
    name = "llama.cpp (cortex-cuda)";
    baseUrl = "http://10.9.2.2:8080/v1";
    api = "openai-completions";
    apiKey = "llama-cpp";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = "qwen3.8-27b-q4-256k";
        name = "Qwen 3.8 27B Q4 (llama-cpp 256K VRAM)";
        reasoning = true;
        contextWindow = 262144;
        maxTokens = 32768;
      }
      {
        id = "qwen3.8-27b-q6-128k";
        name = "Qwen 3.8 27B Q6 (llama-cpp 128K VRAM)";
        reasoning = true;
        contextWindow = 131072;
        maxTokens = 32768;
      }
    ];
  };
}
