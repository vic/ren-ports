# The hubs genie-guard pulls from, and the peers file the xmsg leaf loads.
{ ren, lib }:
{ cluster, xmsg-nodes }:
let
  sh = import ./_genie-guard-shared.nix;
  cfg = cluster.k8s-ai-genie-guard;
  hostOf = h: ren.host.${h};
  # The leaf pulls from every peer in its file, each mailbox on its own.
  hubs = map (
    h:
    let
      host = hostOf h;
    in
    {
      name = h;
      inherit host;
      ip = lib.head (ren.helpers.ipv4Of host);
      port = host.dev-ai-mcp-xmsg.federation.nodes.${host.system-owner.name}.port;
    }
  ) ([ cfg.hub ] ++ cfg.devHubs);
  # Service nodes that screen through this pod (services/matrix-xmsg.nix `guards`)
  # are hubs too: the pod collects their guard requests from them.
  serviceHubs = lib.filter (n: lib.elem "${sh.name}@${sh.name}.${sh.namespace}" (n.guards or [ ])) xmsg-nodes;
  # `list` lets the leaf answer the hub's list query from its mailbox. Without it
  # the leaf withholds list, and every bare send on the hub is `unavailable`
  # (xmsg XA6). The leaf has no listener of its own.
  entry = address: identities: {
    inherit address identities;
    ca = "${sh.tlsDir}/ca.crt";
    allow = [ "list" ];
  };
in
{
  inherit cfg hubs serviceHubs;
  hub = hostOf cfg.hub;
  # A CA entry is keyed by the node name its identity derives, `<user>.<host>`
  # (xmsg README 7.0); the leaf routes each reply to the peer of the origin's node.
  peers = lib.listToAttrs (
    map (h: {
      name = "${h.host.system-owner.name}.${h.name}";
      value = entry "${h.ip}:${toString h.port}" [
        "spiffe://json64.dev/host/${h.name}/user/${h.host.system-owner.name}"
      ];
    }) hubs
    ++ map (n: {
      inherit (n) name;
      value = entry "${n.lanIp}:${toString n.port}" [ n.identity ];
    }) serviceHubs
  );
  # Federation endpoints the pod may reach.
  egressTargets = map (h: { inherit (h) ip port; }) hubs ++ map (n: { ip = n.lanIp; inherit (n) port; }) serviceHubs;
}
