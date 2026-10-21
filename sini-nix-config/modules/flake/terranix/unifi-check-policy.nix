# Fixture: a policy renders one LAN_IN accept rule and one address group
# per source environment from its cluster's node addresses, a
# same-environment source renders none, and an unknown cluster is refused.
{ ren, ... }:
{
  ren.aspects.flake-terranix-unifi-check-policy = {
    at = ren.kinds.system;
    checks =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        inherit (import ./_unifi-lib.nix { inherit lib; }) key;
        renderGatewayPolicies = import ./_unifi-policies.nix { inherit lib key; };
        node = clusterName: env: ip: {
          inherit clusterName ip;
          environment.name = env;
        };
        args = {
          nodes = [
            (node "c1" "p" "10.1.0.3")
            (node "c1" "p" "10.1.0.2")
            (node "c2" "d" "10.2.0.5")
          ];
          policies = [
            {
              name = "svc-to-h";
              protocol = "tcp";
              port = "8081";
              destination = {
                environment = "d";
                ip = "10.2.0.9";
              };
              sources.clusters = [
                "c1"
                "c2"
              ];
            }
          ];
        };
        rendered = renderGatewayPolicies args;
        inherit (rendered.resource) unifi_firewall_rule unifi_firewall_group;
        refused =
          a: !(builtins.tryEval (builtins.deepSeq (renderGatewayPolicies (args // a)) null)).success;
        ok =
          builtins.attrNames unifi_firewall_rule == [ "svc_to_h_from_p" ]
          && unifi_firewall_rule.svc_to_h_from_p == {
            name = "svc-to-h from p";
            ruleset = "LAN_IN";
            action = "accept";
            enabled = true;
            protocol = "tcp";
            dst_address = "10.2.0.9";
            dst_port = "8081";
            rule_index = 20501;
            src_firewall_group_ids = [ "\${unifi_firewall_group.svc_to_h_from_p.id}" ];
          }
          && unifi_firewall_group == {
            svc_to_h_from_p = {
              name = "svc-to-h from p";
              type = "address-group";
              members = [
                "10.1.0.2"
                "10.1.0.3"
              ];
            };
          }
          && refused { policies = map (p: p // { sources.clusters = [ "c3" ]; }) args.policies; };
      in
      {
        unifi-gateway-policy-render =
          assert lib.assertMsg ok "unifi-gateway-policy-render:\n${builtins.toJSON rendered}";
          pkgs.writeText "unifi-gateway-policy-render" (builtins.toJSON rendered);
      };
  };
}
