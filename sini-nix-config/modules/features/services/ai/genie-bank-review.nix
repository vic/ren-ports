# Hindsight write token for the `genie` bank (rekey target of the generator in k8s-ai-hindsight).
# Per-user and 0400. Included for sini@bitstream.
{ ... }:
{
  ren.aspects.svc-ai-genie-bank-review.homeManager =
    { config, ... }:
    {
      age.secrets.hindsight-write-token-genie = {
        rekeyFile = ../../../../.secrets/env/prod/hindsight/write-token-genie.age;
        mode = "400";
        path = "${config.home.homeDirectory}/.config/genie-bank-review/write-token";
      };
    };
}
