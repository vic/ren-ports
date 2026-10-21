# xmsg-nodes: this user's federation node on this host, emitted at the user's own scope
# so the peering rules deliver it (the syncthing `peer` pattern).
# Peering (policies/xmsg.nix) is the xmsg-nodes channel `to` (channels/sync-nz.nix); den.schema.user.includes is `at` below.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  xl = import ./_xmsg-lib.nix { inherit lib; self = ../../../..; };
in
{
  ren.aspects.dev-ai-mcp-xmsg-node-xmsg-nodes = {
    at = ren.kinds.user;
    xmsg-nodes =
      {
        environment,
        host,
        user,
        ...
      }:
      lib.optionals (host.dev-ai-mcp-xmsg.federation.nodes ? ${user.name}) [
        {
          name = xl.nodeName host.name user.name;
          address = "${host.name}.ts.${environment.domain}:${toString host.dev-ai-mcp-xmsg.federation.nodes.${user.name}.port}";
          identity = xl.spiffeOf host.name user.name;
        }
      ];
  };
}
