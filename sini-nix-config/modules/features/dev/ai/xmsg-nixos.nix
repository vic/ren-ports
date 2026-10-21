# xmsg nixos half: federation CA secrets + per-leaf nftables rules. Same aspect as xmsg.nix.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.dev-ai-mcp-xmsg = {

    nixos =
      {
        config,
        host,
        fleet-k3s-nodes,
        xmsg-leaves,
        ...
      }:
      let
        xl = import ./_xmsg-lib.nix { inherit lib; self = ../../../..; };
        nodes = host.dev-ai-mcp-xmsg.federation.nodes;
        ca = name: deps: script: {
          rekeyFile = xl.caDir + "/${name}.age";
          intermediary = true;
          generator = {
            inherit script;
            dependencies = deps;
          };
          settings.cn = "json64.dev xmsg ${name} CA";
        };
        root = config.age.secrets.xmsg-ca-root;
        leavesOf = name: lib.filter (l: lib.elem name l.hubs) xmsg-leaves;
        leafRules = lib.concatStrings (
          lib.concatLists (
            lib.mapAttrsToList (
              user: node:
              lib.concatMap (
                leaf:
                let
                  ks = lib.filter (n: n.clusterName == leaf.cluster) fleet-k3s-nodes;
                in
                assert lib.assertMsg (
                  ks != [ ]
                ) "xmsg federation: leaf ${leaf.identity}'s cluster ${leaf.cluster} has no nodes";
                map (n: ''
                  ip saddr ${n.ip} tcp dport ${toString node.port} accept comment "xmsg leaf ${leaf.identity}: ${n.hostname}"
                '') (lib.sort (a: b: a.hostname < b.hostname) ks)
              ) (leavesOf (xl.nodeName host.name user))
            ) nodes
          )
        );
      in
      {
        options.xmsg.federationPorts = lib.mkOption {
          type = lib.types.attrsOf lib.types.port;
          default = { };
          internal = true;
          description = "Federation port of each xmsg node on this host, by node name.";
        };

        config = lib.mkMerge [
          {
            assertions = [
              {
                assertion = lib.allUnique (lib.attrValues config.xmsg.federationPorts);
                message = "xmsg federation: two nodes on ${host.name} share a port: ${builtins.toJSON config.xmsg.federationPorts}.";
              }
            ];
            xmsg.federationPorts = lib.mapAttrs' (user: n: lib.nameValuePair (xl.nodeName host.name user) n.port) nodes;
          }
          (lib.mkIf (nodes != { }) {
            assertions = lib.mapAttrsToList (user: _: {
              assertion = config.users.users ? ${user};
              message = "xmsg federation: ${host.name} declares a node for ${user}, who has no account here.";
            }) nodes;

            # No firewall rule for peers: the tailnet interface is trusted.
            age.secrets = {
              xmsg-ca-root = ca "root" [ ] "x509-ca-root";
              xmsg-ca-host-intermediate = ca "host-intermediate" [ root ] "x509-ca-intermediate";
              xmsg-ca-cluster-intermediate = ca "cluster-intermediate" [ root ] "x509-ca-intermediate";
            }
            // lib.mapAttrs' (
              user: _: lib.nameValuePair (xl.leafName user) (xl.leafSecret { inherit config host user; })
            ) nodes;

            # nftables syntax: the iptables backend ignores it, leaving the port closed.
            networking.nftables.enable = lib.mkIf (leafRules != "") true;
            networking.firewall.extraInputRules = lib.mkIf (leafRules != "") leafRules;
          })
        ];
      };
  };
}
