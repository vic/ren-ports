# genie-expert: clean public clones, fetched hourly (see genie-expert.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  l = import ./_genie-expert-lib.nix;
in
{
  ren.aspects.svc-ai-genie-expert.nixos =
    { host, pkgs, ... }:
    let
      cfg = host.svc-ai-genie-expert;

      # Clones each repo, or resets it to the published main and removes
      # anything else, so the clone is exactly the published tree. Every repo is
      # tried; any failure fails the unit.
      fetch = pkgs.writeShellScript "genie-public-repos" ''
        fail=0
        for r in "$@"; do
          d="$STATE_DIRECTORY/$r"
          if [ -d "$d/.git" ]; then
            git -C "$d" fetch --quiet origin main &&
              git -C "$d" reset --quiet --hard FETCH_HEAD &&
              git -C "$d" clean --quiet -ffdx
          else
            rm -rf "$d" && git clone --quiet --branch main "https://github.com/sini/$r.git" "$d"
          fi || { echo "genie-public-repos: $r failed" >&2; fail=1; }
        done
        exit "$fail"
      '';
    in
    {
      systemd.services.genie-public-repos = {
        description = "genie: clean clones of the public repos for the public tier";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.git ];
        environment = {
          HOME = "/var/empty";
          GIT_CONFIG_NOSYSTEM = "1";
        };
        serviceConfig = {
          Type = "oneshot";
          User = l.user "public";
          Group = l.user "public";
          StateDirectory = lib.removePrefix "/var/lib/" l.publicClones;
          ExecStart = "${fetch} ${lib.escapeShellArgs cfg.publicRepos}";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };

      systemd.timers.genie-public-repos = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "1h";
        };
      };
    };
}
