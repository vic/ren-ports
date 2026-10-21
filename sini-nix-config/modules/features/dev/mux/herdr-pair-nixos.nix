{ lib, inputs, ... }:
{
  ren.aspects.dev-mux-herdr-pair.nixos =
    {
      host,
      pkgs,
      resolved-users,
      ...
    }:
    let
      cfg = host.dev-mux-herdr-pair;
      herdr = "${inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr}/bin/herdr";

      resolvedNames = map (u: u.name) resolved-users;

      # Guest key strings, sourced from the guest's own registry entry
      # (single source of truth, no duplicated pubkeys).
      keysFor = guest: lib.concatMap (u: u.sshKeys) (builtins.filter (u: u.name == guest) resolved-users);

      # restrict = drop pty + all forwarding + exec; pty re-enables the tty
      # herdr's TUI needs; command pins the one allowed action.
      forcedKey = key: ''restrict,pty,command="${herdr} session attach ${cfg.session}" ${key}'';

      # Only wire owners that actually exist on this host.
      activePairs = lib.filterAttrs (owner: _: builtins.elem owner resolvedNames) cfg.pairs;
    in
    lib.mkIf (activePairs != { }) {
      users.users = lib.mapAttrs (_owner: guests: {
        openssh.authorizedKeys.keys = map forcedKey (lib.concatMap keysFor guests);
      }) activePairs;
    };
}
