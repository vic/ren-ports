# HyperQwen pinned inputs: hubFiles builder and the servable-checkpoint catalogue.
{ lib }:
{
  hubFiles =
    pkgs: repo: rev: files:
    pkgs.linkFarm "${baseNameOf repo}-${builtins.substring 0 7 rev}" (
      lib.mapAttrsToList (path: hash: {
        name = path;
        path = pkgs.fetchurl {
          url = "https://huggingface.co/${repo}/resolve/${rev}/${path}";
          name = baseNameOf path;
          inherit hash;
        };
      }) files
    );

  # Servable checkpoints, each pinned file by file at a Hub revision. `prepared`:
  # already in the served shape (int8/int4 heads, draft vocab), so it is served as-is
  # via MODEL=; otherwise upstream's prepare requantizes it in place on first start.
  models = {
    "qwen3.8-27b" = {
      repo = "dbirks/Qwen3.8-27B-W4A16-AutoRound";
      rev = "1f05c441c4e64ae0549de44fa9ea5a6d43610314";
      dir = "Qwen3.8-27B-W4A16-AutoRound";
      prepared = false;
      files = {
        "chat_template.jinja" = "sha256-w8+eNKv0+eNsLXIWWqnBMtPipyW2wlhqqjqK+deoEEE=";
        "config.json" = "sha256-MXbo7x+KahHKGJQ2qK2SRZc9QgpOtazKZ74/sKXS+Yw=";
        "generation_config.json" = "sha256-GkULdaVL+eb/3Ggdi3ZNRTBh3S0nHfM/z+1GlJtnw94=";
        "model-00001-of-00007.safetensors" = "sha256-ayrcTxuTOG7t0DOmLGMiG/heeJwJraj/Q5OcVenwYlA=";
        "model-00002-of-00007.safetensors" = "sha256-oiP6SHg0dJoU2G1Vivmk1Xmbeb6bwove+kPu0FXRBXg=";
        "model-00003-of-00007.safetensors" = "sha256-hxlWesgidorGGHKJRgTTpNE/LtvSLJvTxGgOvIPiTKU=";
        "model-00004-of-00007.safetensors" = "sha256-j6+NSlfGm5uW4nxOq/G6DKrdPUg0TW9l3xfzDaKn5uM=";
        "model-00005-of-00007.safetensors" = "sha256-CZS7jZHAfO78S//9Ont/0RDMm9POhlvcsoIavwKgL6s=";
        "model-00006-of-00007.safetensors" = "sha256-VaFO550+WmWocx2JQm9N9Hfovcfap5dtQSVNivuUMvA=";
        "model-00007-of-00007.safetensors" = "sha256-aGbPitzMxMxqAOdLwCXxp3T7UhA7cPJnTQKIJylRpzM=";
        "model.safetensors.index.json" = "sha256-Q7MP/R4vlAoI4uoD9gOa0mAIlJr3QViFW+7sKyzXmoY=";
        "model_extra_tensors.safetensors" = "sha256-HYJoqoWs4JOlYePntjudOQ2sHNVakM1VtexQnDydqf4=";
        "processor_config.json" = "sha256-2J70nOnNN/v1EBWOE8HvBj2ShkEcHskEmTLb4EhxQ7E=";
        "quantization_config.json" = "sha256-LzEiqlfdLzX9qOCPPhwMpOFrcqbto/JqQ1RV3+f9LVA=";
        "tokenizer.json" = "sha256-BrlQk1LSr1A4GrIkfgg7gNMtXAq6kcJyyp/3Kbag5SM=";
        "tokenizer_config.json" = "sha256-X3qg2BAADEoJQLNcjxblbDQ5Jg/MwToyGCbrw8zyUB8=";
      };
    };
    # Swift (reasoning-efficiency LoRA) + abliterated, through upstream's own recipe
    # (docs/third-party-checkpoints.md). fc10fe7 is past 29c95a9, which removed the
    # stale int8 MTP tensors that broke SPEC=mtp.
    "swift-qwen3.8-27b" = {
      repo = "ultimaterex/Swift-Qwen3.8-27B-Uncensored-W4A16-AutoRound";
      rev = "fc10fe71940f22d01169685358f1a5e82422ac2a";
      dir = "Swift-Qwen3.8-27B-Uncensored-W4A16-AutoRound";
      prepared = true;
      files = {
        "chat_template.jinja" = "sha256-liKievYWpSRih/lXJJYSh+wXq+znLzRVmHGuuFKziVo=";
        "config.json" = "sha256-kUHYu/jeyqi7i8XeKxs/9wm0WhYxnqs6siDdqs1WPyo=";
        "generation_config.json" = "sha256-Ai4o0ieP+aHrVCFjr5o/ZB9g2bIXXceknJ1/XyrAvW4=";
        "model-00001-of-00004.safetensors" = "sha256-8FGefe58DGyz0oTNWMoSrwPX7VwkSn+ZrHaYk8V14bk=";
        "model-00002-of-00004.safetensors" = "sha256-s0ZS8QDg8t8KLmybP/5KqOupjm6Ajau9oQCua85X4Ho=";
        "model-00003-of-00004.safetensors" = "sha256-/+UkTlk/ciF5aeCm4tg89noV4RkmwkVXC8erSQE/f0k=";
        "model-00004-of-00004.safetensors" = "sha256-pLGyxX070hCRec0ny9W2/0kzJuAiW7HvbQTebv6+spM=";
        "model.safetensors.index.json" = "sha256-3Sa8PczO7CpxXeXf7V3mdvtM1orQqK/IIZtWQTu8hqY=";
        "model_extra_tensors.safetensors" = "sha256-gK/WVxb4ed2mofmFDZR+HGUWYbFKdd17SlCohdbN/eI=";
        "mtp_draft_vocab_ids.pt" = "sha256-ivkChhbkGTLgyUnNU2TS2gpp0VN1r5u0BMqx5Ncj9YE=";
        "preprocessor_config.json" = "sha256-JyJUUKycZSmHLuGST8sJYv9WNINPgXBA9EQRgRb05RY=";
        "processor_config.json" = "sha256-v7wkr1mj5zqc0GU7jUrnWN+uxOPmwV37HGyO6NVoPIU=";
        "quantization_config.json" = "sha256-OU2srRvY4gXUINvFWsPYe0/pixFEeeizTyybkPPJIvM=";
        "tokenizer.json" = "sha256-BrlQk1LSr1A4GrIkfgg7gNMtXAq6kcJyyp/3Kbag5SM=";
        "tokenizer_config.json" = "sha256-eS+j8MuIsRHlTvMTTIc1MQCMTfRx0QjaF5A0JuMIqns=";
      };
    };
  };
}
