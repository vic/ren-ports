# ninfer: client-source resolution and firewall rules (see ninfer.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.svc-ai-ninfer.nixos =
    {
      host,
      fleet-k3s-nodes,
      host-addrs,
      fleet-ninfer-clients,
      ...
    }:
    let
      cfg = host.svc-ai-ninfer;

      # Each admitted source with the hosts it admits.
      addrsOf =
        kind: name: srcs:
        if srcs == [ ] then throw "ninfer: client ${kind} ${name} has no address" else srcs;
      sources = lib.mapAttrs (_: map (s: s.name)) (
        lib.groupBy (s: s.ip) (
          lib.concatMap (
            c:
            addrsOf "cluster" c (
              map (n: {
                inherit (n) ip;
                name = n.hostname;
              }) (lib.filter (n: n.clusterName == c) fleet-k3s-nodes)
            )
          ) cfg.clients.clusters
          ++ lib.concatMap (
            h:
            addrsOf "host" h (
              map (ip: {
                inherit ip;
                name = h;
              }) (lib.concatMap (e: e.ipv4) (lib.filter (e: e.hostname == h) host-addrs))
            )
          ) cfg.clients.hosts
          ++ lib.concatMap (
            c:
            map (ip: {
              inherit ip;
              name = c.hostname;
            }) (if c.ipv4 != [ ] then c.ipv4 else [ c.network ])
          ) fleet-ninfer-clients
        )
      );
    in
    {
      # The client rules below are nftables syntax, which the iptables
      # backend ignores, leaving the port closed to every source.
      networking.nftables.enable = lib.mkIf (cfg.clients != null) true;

      networking.firewall =
        if cfg.clients == null then
          { allowedTCPPorts = [ cfg.port ] ++ cfg.alsoAdmitPorts; }
        else
          assert lib.assertMsg (sources != { }) "ninfer: clients resolve to no address";
          {
            # One rule per source, which a network and an address inside it
            # would overlap in one set; the comment names the hosts it admits.
            extraInputRules = lib.concatStrings (
              lib.concatMap (
                port:
                lib.mapAttrsToList (ip: names: ''
                  ip saddr ${ip} tcp dport ${toString port} accept comment "ninfer: ${
                    lib.concatStringsSep " " (lib.sort (x: y: x < y) (lib.unique names))
                  }"
                '') sources
              ) ([ cfg.port ] ++ cfg.alsoAdmitPorts)
            );
          };
    };
}
