# xmsg (github:sini/xmsg): lists running agent sessions and delivers messages into
# them. Federation nodes `<user>.<host>` authenticate by CA (spiffe identity, leaf signed
# by the host intermediate; root/intermediates are fleet-wide `intermediary` secrets under
# .secrets/xmsg-ca). Peers are derived from xmsg-nodes emissions, never listed.
# Nixos half (CA, firewall): xmsg-nixos.nix. Home-manager half: xmsg-hm.nix. Node emission: xmsg-nodes.nix. Check: xmsg-check.nix.
{ ren, lib, inputs, ... }:
{
  ren.kinds.machine.dev-ai-mcp-xmsg = ren.lib.opt (lib.types.submodule {
    options = {
      genieGuard.ninferUrl = lib.mkOption {
        type = (ren.helpers.types.match "https?://.+");
        default = "http://10.9.2.2:18020/v1";
        description = "OpenAI-compatible endpoint genie-guard asks for its verdicts (hyperqwen on cortex-cuda).";
      };
      federation.nodes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.port = lib.mkOption {
              type = ren.helpers.types.port;
              default = 7788;
              description = "This node's federation listener port (federation plan 6.4); each node on a host needs its own.";
            };
          }
        );
        default = { };
        description = "Users on this host that run an xmsg federation node, `<user>.<host>`, each with a CA-signed leaf `xmsg-<user>-fed-ca` in the host's secretPath. Declaring one needs `agenix generate`, `git add` of the .age and .crt files, and `agenix rekey`.";
      };
    };
  }) { };

  ren.aspects.dev-ai-mcp-xmsg = {
    flake-inputs.xmsg = {
      url = "github:sini/xmsg";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-inputs.genie-agent = {
      url = "github:sini/genie-agent";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # The bot's matrix skill ships with the bot, so it changes with the bot's protocol.
    agent-extensions =
      { pkgs, ... }:
      {
        type = "skill";
        skills.matrix = inputs.matrix-xmsg.packages.${pkgs.stdenv.hostPlatform.system}.matrix-skill;
      };

    homeManagerModules = { ... }: [ inputs.xmsg.homeManagerModules.xmsg ];
  };
}
