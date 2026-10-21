# genie-expert: tier homes (tmpfiles), Claude sandbox settings, persistence (see genie-expert.nix).
{ lib, ... }:
let
  l = import ./_genie-expert-lib.nix;
in
{
  ren.aspects.svc-ai-genie-expert = {
    nixos =
      { config, pkgs, ... }:
      let
        tokenPath = "${config.age.secretsDir}/${l.secret}";

        # The persistence roots holding something under a tier's home.
        persistRoots =
          tier:
          lib.attrNames (
            lib.filterAttrs (
              _: p: lib.any (d: lib.hasPrefix "${l.homeOf tier}/" d.directory) p.directories
            ) config.environment.persistence
          );

        settings = (pkgs.formats.json { }).generate "genie-claude-settings.json" {
          sandbox = {
            enabled = true;
            allowUnsandboxedCommands = false;
            filesystem.denyRead = [
              tokenPath
              "/run/agenix.d"
              "/run/credentials"
              "/proc/*/environ"
            ];
            credentials.envVars = [
              {
                name = "CLAUDE_CODE_OAUTH_TOKEN";
                mode = "deny";
              }
            ];
          };
          # The same paths for Claude's own Read tool, which the sandbox does not wrap.
          permissions.deny = [
            "Read(/${tokenPath})"
            "Read(//run/agenix.d/**)"
            "Read(//run/credentials/**)"
            "Read(//proc/*/environ)"
          ];
        };
      in
      {
        # The shared tree is root-owned and holds only mount points and the clones.
        # Each home is 0700 and its tier's own, on the live path and on its
        # persistence source. Impermanence creates a persisted entry's parents
        # root 0755 and copies the source's mode onto the live directory at
        # every activation, and createHome skips a home that already exists, so
        # these `d` rules (which also fix an existing directory) are what makes
        # the mode authoritative. They run before any service (sysinit.target).
        systemd.tmpfiles.rules = [
          "d ${l.shared} 0755 root root -"
          "d ${l.shared}/repos 0755 root root -"
          "d ${l.shared}/memory 0755 root root -"
        ]
        ++ lib.concatMap (
          tier:
          map (root: "d ${root}${l.homeOf tier} 0700 ${l.user tier} ${l.user tier} -") (
            [ "" ] ++ persistRoots tier
          )
          ++ [ "L+ ${l.homeOf tier}/.claude/settings.json - - - - ${settings}" ]
        ) l.tiers;
      };

    # Only Claude's state persists: the repo mount points inside the trusted home
    # must not propagate into /persist.
    persist = {
      directories =
        map (tier: {
          directory = "${l.homeOf tier}/.claude";
          user = l.user tier;
          group = l.user tier;
          mode = "0700";
        }) l.tiers
        ++ [
          {
            directory = l.publicClones;
            user = l.user "public";
            group = l.user "public";
            mode = "0755";
          }
        ];
      files = map (tier: "${l.homeOf tier}/.claude.json") l.tiers;
    };
  };
}
