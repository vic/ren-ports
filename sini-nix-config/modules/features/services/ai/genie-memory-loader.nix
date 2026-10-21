# Hindsight write token for the `genie-memory` bank. Per-user and 0400. Included for sini@cortex.
{ ... }:
{
  ren.aspects.svc-ai-genie-memory-loader.homeManager =
    { config, ... }:
    {
      age.secrets.hindsight-write-token-genie-memory = {
        rekeyFile = ../../../../.secrets/env/prod/hindsight/write-token-genie-memory.age;
        mode = "400";
        path = "${config.home.homeDirectory}/.config/hindsight/genie-memory-write-token";
      };
    };
}
