# genie-tier1: genie-agent Tier 1 (github:sini/genie-agent, nixosModules.default), answers
# @genie mentions routed by svc-matrix-xmsg `roomRoutes`. Runs as the system owner.
#   model      hyperqwen on cortex-cuda, key as systemd credential (never in the store)
#   guard-in   the pod guard (k8s-ai-genie-guard); local genie-guard unit stays off
#   guard-out  on, against the same model
#   experts    genie-support until the expert tiers come up (GI-6)
{ inputs, ... }:
{
  ren.aspects.svc-ai-genie-tier1 = {
    nixos =
      { host, config, ... }:
      {
        imports = [ inputs.genie-agent.nixosModules.default ];

        services.genie-agent = {
          enable = true;
          user = host.system-owner.name;
          xmsgSocket = "/run/user/${toString config.users.users.${host.system-owner.name}.uid}/xmsg";
          stateDir = "/var/lib/genie-agent";
          model = {
            baseUrl = "http://10.9.2.2:18020/v1";
            id = "qwen3.8-27b";
            keyFile = "${config.users.users.${host.system-owner.name}.home}/.config/hyperqwen/api-key";
          };
          tier1.searxngUrl = host.dev-ai-mcp-searxng.endpoint;
          hindsightUrl = "http://10.11.0.20:8888";
          s3 = null;
          guardRef = "genie-guard@genie-guard.genie";
          experts = {
            public = "genie-support@${host.system-owner.name}.${host.name}";
            trusted = "genie-support@${host.system-owner.name}.${host.name}";
          };
        };

        # guard.enable also declares a local genie-guard unit; screening stays on, the unit does not.
        systemd.services.genie-guard.enable = false;
      };

    persist =
      { host, ... }:
      {
        directories = [
          {
            directory = "/var/lib/genie-agent";
            user = host.system-owner.name;
            group = "users";
            mode = "0700";
          }
        ];
      };
  };
}
