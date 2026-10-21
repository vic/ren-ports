# genie-expert: systemd units, clone fetcher, refresh timer (see genie-expert.nix).
{
  ren,
  lib,
  inputs,
  ...
}:
let
  l = import ./_genie-expert-lib.nix;
in
{
  ren.aspects.svc-ai-genie-expert.nixos =
    {
      config,
      host,
      pkgs,
      ...
    }:
    let
      hasToken = builtins.pathExists (host.secretPath + "/${l.secret}.age");
      tokenPath = "${config.age.secretsDir}/${l.secret}";

      views = {
        public = {
          repos = l.publicClones;
          memory = "${l.publicClones}/genie-agent/support-memory";
        };
        trusted = {
          repos = l.ownerCheckouts;
          memory = "/home/${host.system-owner.name}/.claude/memory";
        };
      };

      start = import ./_genie-expert-start.nix { inherit lib inputs pkgs; };

    in
    {
      systemd.services = {
        # Defined either way, enabled with the token, so the views stay checkable
        # (genie-expert-check.nix) before the owner has created it.
        "genie-expert@" = {
          enable = hasToken;
          description = "genie: Claude Code Opus expert for @genie, %i tier";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          # The trusted checkouts belong to another user, so git refuses them
          # without this.
          environment = {
            GIT_CONFIG_COUNT = "1";
            GIT_CONFIG_KEY_0 = "safe.directory";
            GIT_CONFIG_VALUE_0 = "*";
          };
          serviceConfig = {
            Type = "forking";
            ExecStart = start;
            LoadCredential = "claude-token:${tokenPath}";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            Restart = "on-failure";
          };
        };
      }
      // lib.listToAttrs (
        map (
          tier:
          lib.nameValuePair "genie-expert@${tier}" {
            overrideStrategy = "asDropin";
            enable = hasToken;
            wantedBy = [ "multi-user.target" ];
            after = lib.optional (tier == "public") "genie-public-repos.service";
            wants = lib.optional (tier == "public") "genie-public-repos.service";
            # Here, not on the template: a drop-in's PATH replaces the template's.
            path = with pkgs; [
              bubblewrap
              socat
              git
              ripgrep
              tmux
            ];
            environment.HOME = l.homeOf tier;
            serviceConfig = {
              User = l.user tier;
              Group = l.user tier;
              RuntimeDirectory = "genie-expert-${tier}";
              WorkingDirectory = l.homeOf tier;
              ReadWritePaths = [ (l.homeOf tier) ];
              BindReadOnlyPaths = [
                "${views.${tier}.repos}:${l.shared}/repos"
                "${views.${tier}.memory}:${l.shared}/memory"
              ];
            };
          }
        ) l.tiers
      );

    };
}
