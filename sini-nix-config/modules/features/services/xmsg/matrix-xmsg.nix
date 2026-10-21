# matrix-xmsg (github:sini/matrix-xmsg): the @genie support bot; settings field, flake input, persist.
# Service body in matrix-xmsg-nixos.nix. Needs rooms set to enable.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-matrix-xmsg = ren.lib.opt (lib.types.submodule {
    options = {
      rooms = lib.mkOption {
        type = lib.types.listOf ((ren.helpers.types.match "![^:]+(:.+)?")); # room v12 IDs have no :server
        default = [ ];
        example = [ "!abcdef:json64.dev" ];
        description = "Room IDs (not aliases) the bot serves. Empty keeps the service disabled; `matrix-bot-provision` prints the value.";
      };
      expertRef = lib.mkOption {
        type = lib.types.str;
        default = "genie-support";
        description = "Label of the xmsg session the bot relays to, on this host's own node: the bot addresses it as `<label>@<user>.<host>`, so an unreachable peer never makes it `unavailable`.";
      };
      roomRoutes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              expertRef = lib.mkOption {
                type = lib.types.str;
                description = "Label of the xmsg service or session this room relays to, on this host's own node, as for `expertRef`.";
              };
              screenMentions = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Whether the bot screens this room's mentions itself; false for an expert that screens its own input. null keeps the bot's default.";
              };
            };
          }
        );
        default = { };
        example = {
          "!abcdef:json64.dev" = {
            expertRef = "genie";
            screenMentions = false;
          };
        };
        description = "Per-room routing (matrix-xmsg M34) for rooms in `rooms`. Rooms not listed relay to `expertRef`, screened.";
      };
      guardRef = lib.mkOption {
        type = lib.types.str;
        default = "genie-guard@genie-guard.genie";
        description = "xmsg address of the guard the bot screens through. The default is the pod's guard (kubernetes/services/ai/genie-guard.nix), which takes this bot's node as a hub while the bot screens through it.";
      };
      screenMentions = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the bot screens mentions through `guardRef` (rooms may override it in `roomRoutes`).";
      };
      screenSolicited = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the bot screens agent-opened threads through `guardRef`.";
      };
      xmsgPort = lib.mkOption {
        type = ren.helpers.types.port;
        default = 7791;
        description = "Federation port of the bot's xmsg node, distinct from every other node's on the host.";
      };
      extraTrustedMxids = lib.mkOption {
        type = lib.types.listOf ((ren.helpers.types.match "@[^:]+:.+"));
        default = [ ];
        example = [ "@alice:matrix.org" ];
        description = "Trusted senders beyond kanidm `admins`: accounts on other homeservers, which kanidm cannot list.";
      };
    };
  }) { };

  ren.aspects.svc-matrix-xmsg = {
    flake-inputs.matrix-xmsg = {
      url = "github:sini/matrix-xmsg";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    persist =
      { host, ... }:
      lib.optionalAttrs (host.svc-matrix-xmsg.rooms != [ ]) {
        directories = [
        {
          directory = "/var/lib/matrix-xmsg";
          mode = "0755";
          user = "matrix-xmsg";
          group = "matrix-xmsg";
        }
        {
          directory = "/var/lib/matrix-xmsg-xmsg";
          mode = "0700";
          user = "matrix-xmsg";
          group = "matrix-xmsg";
        }
        ];
      };
  };
}
