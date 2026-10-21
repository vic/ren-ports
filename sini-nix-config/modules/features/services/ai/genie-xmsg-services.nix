# genie-xmsg: xmsg@ template, per-tier drop-ins, persisted reply store (see genie-xmsg.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  l = import ./_genie-xmsg-lib.nix;
in
{
  ren.aspects.svc-ai-genie-xmsg = {
    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.svc-ai-genie-xmsg;
      in
      {
        systemd.services = {
          "xmsg@" = {
            description = "xmsg: the %i genie tier's bus";
            serviceConfig = {
              ExecStart = "${lib.getExe pkgs.local.xmsg} serve";
              Restart = "on-failure";
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              NoNewPrivileges = true;
            };
          };
        }
        // lib.listToAttrs (
          map (
            tier:
            lib.nameValuePair "xmsg@${tier}" {
              overrideStrategy = "asDropin";
              wantedBy = [ "multi-user.target" ];
              environment = {
                HOME = l.homeOf tier;
                XDG_RUNTIME_DIR = l.runtimeDir tier;
                XMSG_DB_PATH = "${l.stateDir tier}/xmsg.db";
              }
              // lib.optionalAttrs (cfg.${tier}.sessionsDirs != [ ]) {
                XMSG_SESSIONS_DIR = lib.concatStringsSep ":" cfg.${tier}.sessionsDirs;
              };
              serviceConfig = {
                User = l.user tier;
                Group = l.user tier;
                RuntimeDirectory = lib.removePrefix "/run/" (l.runtimeDir tier);
                RuntimeDirectoryMode = "0700";
                RuntimeDirectoryPreserve = "yes";
                StateDirectory = lib.removePrefix "/var/lib/" (l.stateDir tier);
                StateDirectoryMode = "0700";
              };
            }
          ) l.tiers
        );
      };

    # The reply store survives a reboot (root is wiped).
    persist.directories = map (tier: {
      directory = l.stateDir tier;
      user = l.user tier;
      group = l.user tier;
      mode = "0700";
    }) l.tiers;
  };
}
