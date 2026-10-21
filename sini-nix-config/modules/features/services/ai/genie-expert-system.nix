# genie-expert: tier users, token secret, owner-checkout bind mounts (see genie-expert.nix).
{ lib, ... }:
let
  l = import ./_genie-expert-lib.nix;
in
{
  ren.aspects.svc-ai-genie-expert.nixos =
    {
      config,
      host,
      ...
    }:
    let
      cfg = host.svc-ai-genie-expert;
      ownerHome = "/home/${host.system-owner.name}";
      tokenFile = host.secretPath + "/${l.secret}.age";
      # agenix-rekey refuses a rekeyFile that is not in git, so the secret and the
      # expert stay off until the owner has created it.
      hasToken = builtins.pathExists tokenFile;

      roBind = src: {
        device = src;
        fsType = "none";
        options = [
          "bind"
          "ro"
          "nofail"
        ];
        # The sources are themselves impermanence bind mounts.
        depends = [ src ];
      };
    in
    {
      # The token slot as declared, readable whether or not the token exists yet
      # (age.secrets only carries it once it does); genie-expert-check.nix reads it.
      options.services.genie-expert.tokenSecret = lib.mkOption {
        internal = true;
        readOnly = true;
        type = lib.types.attrs;
        default = {
          rekeyFile = tokenFile;
          # Read only by systemd for LoadCredential, so no genie shell can read it.
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.elem "genie-agent" cfg.publicRepos;
            message = "genie-expert: the public tier's memory is genie-agent's support-memory/, so `publicRepos` must include genie-agent.";
          }
        ];

        users.groups = lib.genAttrs (map l.user l.tiers) (_: { });
        users.users = lib.listToAttrs (
          map (
            tier:
            lib.nameValuePair (l.user tier) {
              group = l.user tier;
              isSystemUser = true;
              useDefaultShell = true;
              home = l.homeOf tier;
              homeMode = "700";
              createHome = true;
              description = "@genie Opus expert, ${tier} tier";
            }
          ) l.tiers
        );

        services.openssh.settings.DenyUsers = map l.user l.tiers;

        warnings = lib.optional (!hasToken) ''
          genie-expert: ${l.secret}.age is absent on ${host.name}, so the expert service is NOT enabled.
          Mint a token with `claude setup-token`, then `agenix edit .secrets/hosts/${host.name}/${l.secret}.age`, `git add` it and `agenix rekey`.
        '';

        # The owner creates the value; nothing here generates it.
        age.secrets = lib.mkIf hasToken { ${l.secret} = config.services.genie-expert.tokenSecret; };

        # Inside the 0700 trusted home, so genie-public cannot even traverse to them.
        fileSystems = lib.listToAttrs (
          map (
            name:
            lib.nameValuePair "${l.ownerCheckouts}/${name}" (roBind "${ownerHome}/Documents/repos/sini/${name}")
          ) cfg.checkouts
        );
      };
    };
}
