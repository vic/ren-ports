# ninfer: endpoint and gateway-policy emissions, flake input, cache dir (see ninfer.nix).
{ ren, lib, ... }:
let
  wantsClients = host: ((host.svc-ai-ninfer or { }).clients or null) != null;
  wantsLeaves = host: ((host.dev-ai-mcp-xmsg or { }).federation or { }).nodes or { } != { };
in
{
  # den.policies.ninfer-collect-client-nodes (+ xmsg-collect-leaf-nodes): a receiver with ninfer.clients or xmsg
  # federation nodes collects every environment's k3s nodes, and ninfer every environment's client records.
  # The same-env/same-cluster `k3s-nodes` and `ninfer-clients` channels cannot reach them, so these two fleet
  # channels pick the receivers on the receiver side (README.md:250 `to`; `when` sees the receiver bindings).
  ren.channels.fleet-k3s-nodes = {
    fold = ren.lib.fold.list;
    to = _: ren.lib.and [ ren.kinds.host (ren.lib.when ({ host, ... }: wantsClients host || wantsLeaves host)) ];
    into = { ... }: n: { fleet-k3s-nodes = n; };
  };
  ren.channels.fleet-ninfer-clients = {
    fold = ren.lib.fold.list;
    to = _: ren.lib.and [ ren.kinds.host (ren.lib.when ({ host, ... }: wantsClients host)) ];
    into = { ... }: c: { fleet-ninfer-clients = c; };
  };

  # The cluster nodes that fleet-k3s-nodes receivers read (hostname, ip, clusterName), emitted where k3s-nodes is.
  ren.aspects.svc-k3s.fleet-k3s-nodes =
    { host, ... }:
    {
      hostname = host.name;
      ip = builtins.head (ren.helpers.ipv4Of host);
      clusterName = host.svc-k3s.clusterName;
    };

  ren.aspects.svc-ai-ninfer = {
    flake-inputs.ninfer-3090.url = "github:Don-Chad/ninfer-3090/release/v0.6.2-rtx3090";

    # Endpoint AND model identity: consumers need the exact `--model-id` and
    # the context/output bounds, not just an address.
    ninfer-endpoints =
      { host, ... }:
      let
        cfg = host.svc-ai-ninfer;
      in
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        inherit (cfg)
          port
          modelId
          maxContext
          maxTokens
          ;
      };

    # The cluster clients' path across the gateway (the hosts share a LAN with it).
    gateway-policies =
      { host, ... }:
      let
        cfg = host.svc-ai-ninfer;
      in
      lib.optional (cfg.clients != null && cfg.clients.clusters != [ ]) {
        name = "ninfer-to-${host.name}";
        protocol = "tcp";
        port = toString cfg.port;
        destination = {
          inherit (host) environment;
          ip = builtins.head (ren.helpers.ipv4Of host);
        };
        sources.clusters = cfg.clients.clusters;
      };

    cache = {
      directories = [
        {
          directory = "/var/lib/private/ninfer";
          user = "ninfer";
          group = "ninfer";
          mode = "0700";
        }
      ];
    };
  };
}
