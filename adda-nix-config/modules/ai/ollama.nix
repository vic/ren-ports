# ai-ollama: local ollama (ROCm) + Alpaca flatpak (not included by default)
{ ren, ... }:
{
  ren.aspects.ai-ollama.os =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        loadModels = [
          # "llama3.1"
          # "mistral"
        ];
      };

      services.flatpak.packages = [
        "com.jeffser.Alpaca"
        "com.jeffser.Alpaca.Plugins.Ollama"
        "com.jeffser.Alpaca.Plugins.AMD"
      ];
    };
}
