# The gateway-policies records as legacy LAN_IN accept rules (the gateway runs
# no zone-based firewall), one per source environment: from an address group
# of the named clusters' node addresses (pods masquerade to them) to the
# destination address and port. Sources in the destination's own environment
# share its LAN and never cross the gateway, so they render none. A cluster
# with no nodes is refused.
# ponytail: rule_index is ruleIndexBase + position; the controller refuses a
# clash, so a second consumer of the block reads the live indices first.
{ lib, key }:
let
  ruleIndexBase = 20500;
in
{ nodes, policies }:
let
  sourcesOf =
    p:
    lib.concatMap (
      c:
      let
        members = builtins.filter (n: n.clusterName == c) nodes;
      in
      if members == [ ] then
        throw "unifi: gateway policy ${p.name} names cluster ${c}, which has no nodes"
      else
        members
    ) p.sources.clusters;
  rulesOf =
    p:
    lib.mapAttrsToList (src: members: {
      name = key "${p.name}-from-${src}";
      group = {
        name = "${p.name} from ${src}";
        type = "address-group";
        members = lib.sort (a: b: a < b) (lib.unique (map (n: n.ip) members));
      };
      rule = {
        name = "${p.name} from ${src}";
        ruleset = "LAN_IN";
        action = "accept";
        enabled = true;
        inherit (p) protocol;
        dst_address = p.destination.ip;
        dst_port = p.port;
      };
    }) (removeAttrs (lib.groupBy (n: n.environment.name) (sourcesOf p)) [ p.destination.environment ]);
  rules = lib.concatMap rulesOf policies;
in
if rules == [ ] then
  { }
else
  {
    resource.unifi_firewall_group = lib.listToAttrs (map (r: lib.nameValuePair r.name r.group) rules);
    resource.unifi_firewall_rule = lib.listToAttrs (
      lib.imap1 (
        i: r:
        lib.nameValuePair r.name (
          r.rule
          // {
            rule_index = ruleIndexBase + i;
            src_firewall_group_ids = [ "\${unifi_firewall_group.${r.name}.id}" ];
          }
        )
      ) rules
    );
  }
