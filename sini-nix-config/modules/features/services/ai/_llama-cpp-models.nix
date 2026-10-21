# llama-cpp model catalogue (see llama-cpp.nix).
# Hashes are the `lfs.oid` HuggingFace reports for each file. `alias` is the
# id llama-server answers to; `settings` are extra llama-server flags.
{
  models = {
    # 13,792,639,168 bytes.
    gpt-oss-20b = {
      url = "https://huggingface.co/unsloth/gpt-oss-20b-GGUF/resolve/main/gpt-oss-20b-F16.gguf";
      hash = "sha256-Tk+c2I1kVuTziecmLspKjVZSEeKyLs6cp6hVYWj/PGY=";
      alias = "gpt-oss-20b";
      # reasoning_effort IS harmony's live knob, and it is pinned here
      # rather than left to each caller: this instance exists to augment
      # the cluster's llama-cpp pool, whose caller is hindsight's retain
      # loop. Retain is prefill-bound extraction -- 7642 tokens in for 67
      # out -- so thinking is latency that buys nothing. Unset does NOT
      # mean off: harmony defaults to medium, which is how a 200-token
      # budget came back here as 200 tokens of reasoning_content and an
      # EMPTY content field. The quotes are load-bearing; the upstream
      # module renders ExecStart with toString, not escapeShellArgs, so
      # systemd does the quote parsing.
      settings.chat-template-kwargs = "'{\"reasoning_effort\":\"low\"}'";
    };
    # club-3090's single-card 262K profile (llamacpp/qwen38-27b-single-iq4xs):
    # q4_0 KV is what fits 262,144 beside 14.3 GB of weights; q8_0 fits 131,072.
    qwen38-27b-iq4xs = {
      url = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf";
      hash = "sha256-QPrEBQ6UA5fb8TCHr9UPRzShGAW/nWXvjd10g0cOYZk=";
      alias = "qwen3.8-27b";
      settings.reasoning-format = "deepseek";
    };
    # 22.4 GB: fits the card whole.
    qwen36-35b-a3b-q4kxl = {
      url = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
      hash = "sha256-cHpVqKQ5fs3kTeDEmdPmjBrR0kDR2mWCa0lJ0QQ/RFA=";
      alias = "qwen3.6-35b-a3b";
      settings.reasoning-format = "deepseek";
    };
    # 31.8 GB: needs n-cpu-moe to hold some experts in host RAM.
    qwen36-35b-a3b-q6kxl = {
      url = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-UD-Q6_K_XL.gguf";
      hash = "sha256-9rbG1c+m8A2WTut63SjrFM50gXNNUGuQaBAHZ4zSxIQ=";
      alias = "qwen3.6-35b-a3b";
      settings.reasoning-format = "deepseek";
    };
  };
}
