# headroom proxy as a launchd agent (darwin). Same aspect as headroom.nix.
{ ... }:
{
  ren.aspects.dev-ai-mcp-headroom = {
    homeDarwin =
      { pkgs, lib, ... }:
      {
        launchd.agents.headroom = {
          enable = true;
          config = {
            ProgramArguments = [
              "${lib.getExe pkgs.local.headroom-ai}"
              "proxy"
              "--host"
              "127.0.0.1"
              "--port"
              "8787"
              "--no-telemetry"
            ];
            # Mirrors the Linux service environment — see there for why these are set.
            EnvironmentVariables = {
              HEADROOM_TELEMETRY = "off";
              HEADROOM_MODE = "cache";
              HEADROOM_LOSSLESS = "1";
              HEADROOM_LOG_MESSAGES = "1";
            };
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
            ThrottleInterval = 5;
          };
        };
      };
  };
}
