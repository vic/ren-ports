# Constants shared by the llama-cpp release, monitor and network policies.
{
  port = 8080;
  # One label across every instance, so the network policies and the
  # PodMonitor are written once instead of per instance.
  engineLabel = "den.ai/engine";
  engineValue = "llama-cpp";
}
