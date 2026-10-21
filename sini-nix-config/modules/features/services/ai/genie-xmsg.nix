# genie-xmsg: one xmsg instance per genie tier, xmsg@public and xmsg@trusted, each
# the bus of its own OS user (xmsg/genie-agent-design.md §5.8 Topology; plan I16).
# xmsg serves HTTP only on $XDG_RUNTIME_DIR/xmsg/http.sock (0600, peer uid ==
# server uid) and binds no TCP without --listen/XMSG_LISTEN, so a process reaches
# only its own user's bus: the tier fence holds by construction. Neither tier
# instance may carry a TCP listen; an assertion refuses one at render time.
#
# The tier users have no login session, so no /run/user/<uid>. Each instance owns
# /run/xmsg-<tier> by RuntimeDirectory= (0700, the tier user, preserved across a
# restart so the units sharing it keep it); services.genie-xmsg.runtimeDir
# exports the path for the units that must set XDG_RUNTIME_DIR to it
# (genie-herdr@ and genie-dispatcher@, I10.2).
#
# Federation (fed ports, node keys, links) is typed data here, inert until xmsg
# ships its federation listener (X1): nothing below passes it to xmsg yet. Each
# node key is an `xmsg-identity` agenix secret owned by its tier user at 0400,
# declared once nodeKeys is set (the owner then generates them).
# Files: this (settings), genie-xmsg-nixos, genie-xmsg-services.
{ ren, lib, ... }:
let
  l = import ./_genie-xmsg-lib.nix;

  tierOptions = tier: {
    sessionsDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Claude session directories of every per-token config directory of the ${tier} tier (`--sessions-dir`, X7). Empty until I10.3 renders the token pool; xmsg then reads ~/.claude/sessions.";
    };
    svcTrustedExes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Executables trusted to register a `svc:` principal on this instance (the dispatcher, X9). Not rendered until X9 ships its flag.";
    };
    fedPort = lib.mkOption {
      type = ren.helpers.types.port;
      # 7788/7789 are the owner's and vic's nodes on bitstream; 7791 is the bot's.
      default = if tier == "public" then 7792 else 7793;
      description = "This node's federation listener port. Inert until X1, but held distinct from every other node's on the host now (mcp/xmsg.nix federationPorts).";
    };
  };

  link = lib.types.submodule {
    options = {
      from = lib.mkOption { type = lib.types.str; };
      to = lib.mkOption { type = lib.types.str; };
      allow = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "send"
            "reply"
            "list"
          ]
        );
      };
      principals = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };
in
{
  ren.kinds.machine.svc-ai-genie-xmsg = ren.lib.opt (lib.types.submodule {
    options = lib.genAttrs l.tiers tierOptions // {
      nodeKeys = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Declare the tiers' federation node keys. agenix-rekey refuses to evaluate a declared key whose .age is absent, and `agenix generate` creates only declared ones, so set this, then run `agenix generate`, `git add` the .age and .crt files, and `agenix rekey`.";
      };
      ownerFedPort = lib.mkOption {
        type = ren.helpers.types.port;
        default = 7788;
        description = "The system owner's node's federation port on this host, held distinct from the tiers'. Inert until X1.";
      };
      links = lib.mkOption {
        type = lib.types.listOf link;
        # The federation plan's one link to genie@bitstream, re-cut per tier. No
        # link joins the tier nodes, or either of them to the owner's.
        default = map (tier: {
          from = "genie";
          to = "${l.user tier}@bitstream";
          allow = [ "send" ];
          principals = [ "genie-expert" ];
        }) l.tiers;
        description = "xmsg-links edges into the tier nodes (federation plan §6.1). Inert until X1.";
      };
    };
  }) { };
}
