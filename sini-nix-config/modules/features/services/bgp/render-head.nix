# FRR config rendering: forwarding, static routes, prefix lists, route maps, router bgp
# header, peer groups, neighbors, address families, extraConfig. All one lib.mkAfter string, as in den.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.svc-bgp.nixos =
    { config, host, ... }:
    let
      cfg = config.services.bgp;
      localAsn = host.svc-bgp.localAsn;
      routerId = builtins.head (ren.helpers.ipv4Of host);

      # Build config lines as lists, then join — avoids nested multiline string indentation issues
      ind = "  ";

      staticRouteLines = lib.optionals (cfg.staticRoutes != [ ]) (
        [ "! Static routes" ] ++ cfg.staticRoutes ++ [ "!" ]
      );

      prefixListLines = lib.optionals (cfg.prefixLists != { }) (
        [ "! Prefix lists" ]
        ++ lib.flatten (
          lib.mapAttrsToList (
            name: entries:
            lib.imap0 (i: entry: "ip prefix-list ${name} seq ${toString ((i + 1) * 10)} ${entry}") entries
          ) cfg.prefixLists
        )
        ++ [ "!" ]
      );

      routeMapLines = lib.optionals (cfg.routeMaps != [ ]) (
        [ "! Route maps" ] ++ cfg.routeMaps ++ [ "!" ]
      );

      mkPeerGroupLines =
        name: group:
        [
          "${ind}neighbor ${name} peer-group"
          "${ind}neighbor ${name} remote-as ${toString group.remoteAs}"
        ]
        ++ lib.optional group.softReconfiguration "${ind}neighbor ${name} soft-reconfiguration inbound"
        ++ lib.optional (
          group.updateSource != null
        ) "${ind}neighbor ${name} update-source ${group.updateSource}"
        ++ lib.optional (
          group.ebgpMultihop != null
        ) "${ind}neighbor ${name} ebgp-multihop ${toString group.ebgpMultihop}"
        ++ lib.optional (
          group.listenRange != null
        ) "${ind}bgp listen range ${group.listenRange} peer-group ${name}";

      peerGroupLines = lib.optionals (cfg.peerGroups != { }) (
        [ "${ind}!" ] ++ lib.flatten (lib.mapAttrsToList mkPeerGroupLines cfg.peerGroups)
      );

      mkNeighborLines =
        neighbor:
        [ "${ind}neighbor ${neighbor.ip} remote-as ${toString neighbor.asn}" ]
        ++ lib.optional neighbor.softReconfiguration "${ind}neighbor ${neighbor.ip} soft-reconfiguration inbound"
        ++ lib.optional (
          neighbor.updateSource != null
        ) "${ind}neighbor ${neighbor.ip} update-source ${neighbor.updateSource}"
        ++ lib.optional (
          neighbor.ebgpMultihop != null
        ) "${ind}neighbor ${neighbor.ip} ebgp-multihop ${toString neighbor.ebgpMultihop}"
        ++ lib.optional (
          neighbor.routeMapIn != null
        ) "${ind}neighbor ${neighbor.ip} route-map ${neighbor.routeMapIn} in"
        ++ lib.optional (
          neighbor.routeMapOut != null
        ) "${ind}neighbor ${neighbor.ip} route-map ${neighbor.routeMapOut} out"
        ++ lib.optional (
          neighbor.allowasIn != null
        ) "${ind}neighbor ${neighbor.ip} allowas-in ${toString neighbor.allowasIn}";

      neighborLines = lib.optionals (cfg.neighbors != [ ]) (
        [ "${ind}!" ] ++ lib.flatten (map mkNeighborLines cfg.neighbors)
      );

      mkAddressFamilyLines =
        family: familyConfig:
        let
          familyName = lib.replaceStrings [ "-" ] [ " " ] family;
          networkLines = map (net: "${ind}${ind}network ${net}") familyConfig.networks;
          neighLines = lib.filter (s: s != "") (
            lib.flatten (
              lib.mapAttrsToList (
                ip: nc:
                lib.optional nc.activate "${ind}${ind}neighbor ${ip} activate"
                ++ lib.optional nc.nextHopSelf "${ind}${ind}neighbor ${ip} next-hop-self"
                ++ lib.optional nc.defaultOriginate "${ind}${ind}neighbor ${ip} default-originate"
              ) familyConfig.neighbors
            )
          );
          peerGroupAfLines = lib.flatten (
            lib.mapAttrsToList (
              name: gc:
              lib.optional gc.activate "${ind}${ind}neighbor ${name} activate"
              ++ lib.optional gc.nextHopSelf "${ind}${ind}neighbor ${name} next-hop-self"
            ) familyConfig.peerGroups
          );
        in
        [
          "${ind}!"
          "${ind}address-family ${familyName}"
        ]
        ++ networkLines
        ++ neighLines
        ++ peerGroupAfLines
        ++ [ "${ind}exit-address-family" ];

      addressFamilyLines = lib.optionals (cfg.addressFamilies != { }) (
        lib.flatten (lib.mapAttrsToList mkAddressFamilyLines cfg.addressFamilies)
      );

      bgpLines = [
        "!"
        "router bgp ${toString localAsn}"
        "${ind}bgp router-id ${routerId}"
        "${ind}no bgp ebgp-requires-policy"
        "${ind}bgp bestpath as-path multipath-relax"
        "${ind}maximum-paths ${toString cfg.maximumPaths}"
        "${ind}bgp allow-martian-nexthop"
      ]
      ++ peerGroupLines
      ++ neighborLines
      ++ addressFamilyLines;

      allLines = [
        "ip forwarding"
        "!"
      ]
      ++ staticRouteLines
      ++ prefixListLines
      ++ routeMapLines
      ++ bgpLines
      ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig;
    in
    {
      services.frr.bgpd.enable = true;
      services.frr.config = lib.mkAfter (lib.concatStringsSep "\n" allLines);
    };
}
