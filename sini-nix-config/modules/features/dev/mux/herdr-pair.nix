# herdr-pair: grant guests attach-only access to a host account's live herdr
# session (e.g. that account's claude-code session).
#
# herdr binds its control socket 0600 (owner-only), so a second unix user cannot
# attach through a shared-group socket. This installs each guest's SSH key on the
# target account, pinned to a single forced command that attaches the named herdr
# session and nothing else: no shell, no scp, no port/agent/X11 forwarding.
#
# Trust (Model A): while attached the guest co-drives as the target account.
# The target account must be running the session first:
#   herdr session attach <session>   (then launch claude-code inside it)
{
  ren,
  lib,
  ...
}:
{
  ren.kinds.machine.dev-mux-herdr-pair = ren.lib.opt (lib.types.submodule {
    options = {
      session = lib.mkOption {
        type = lib.types.str;
        default = "pair";
        description = "herdr session name guests attach. Each owner runs their shared claude-code session under this name (resolved per-account, so every owner has their own).";
      };
      pairs = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        example = {
          sini = [ "vic" ];
        };
        description = ''
          Map of host account owner -> guest registry usernames. Each guest's
          identity.sshKeys are installed on the owner's account behind a forced
          herdr-attach command, granting attach-only access to the owner's
          `session`. Owners not resolved onto this host are ignored.
        '';
      };
    };
  }) { };
}
