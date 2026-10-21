# llama-server probes, all on /health.
port:
let
  health = {
    enabled = true;
    type = "HTTP";
    path = "/health";
    inherit port;
  };
in
{
  liveness = health;
  readiness = health;
  # First boot pulls the weights from HuggingFace before the server answers
  # anything, then loads them onto the GPU. 30 minutes of headroom so
  # liveness cannot kill it mid-download.
  startup = {
    enabled = true;
    custom = true;
    spec = {
      httpGet = {
        path = "/health";
        inherit port;
      };
      periodSeconds = 10;
      failureThreshold = 180;
    };
  };
}
