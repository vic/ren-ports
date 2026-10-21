# ninfer model catalogue (see ninfer.nix).
# Hashes are the `lfs.oid` HuggingFace reports for each file.
{
  models = {
    # Official artifact; agrees with the SHA256SUMS published beside it.
    "qwen3.8-27b" = {
      url = "https://huggingface.co/neroued/Qwen3.8-27B-NInfer/resolve/main/qwen3_8_27b.ninfer";
      hash = "sha256-7sOVZJk9bpx9Xjgzgqdg8JNGXJ0WPsmhvWuAGZUUvz4=";
    };
    # Swift-Qwen3.8-27B-Uncensored (abliterated); 18.2 GB, carries no DFlash payload.
    "swift-qwen3.8-27b" = {
      url = "https://huggingface.co/wacomctl672/Swift-Qwen3.8-27B-Uncensored-ninfer3090/resolve/main/swift_qwen3_8_27b.ninfer";
      hash = "sha256-KyExYgLUy2CCYl4c0XnwO1fYecxyVnBj5IptXnRNyWA=";
    };
    # Upstream's pinned compact v1, the artifact its 3090 results were measured on.
    "qwen3.6-35b-a3b" = {
      url = "https://huggingface.co/neroued/Qwen3.6-35B-A3B-NInfer/resolve/c8b8c1c0df4c74df3c190c6aa3a7f24dc614721c/qwen3_6_35b_a3b.ninfer";
      hash = "sha256-noN4OY0reJp3IktREMdZCtu8b9SszRObkYFXsrnacWM=";
    };
  };
}
