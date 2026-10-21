# The UniFi gateway as code (infra/unifi/README.md): an environment with `unifi`
# set instantiates this module. Exactly one environment may set `unifi`.
# Channels: bgp-peers (hosts of this env), port-forwards (hosts and clusters of
# this env), gateway-policies + k3s-nodes (all hosts; policies cross environments).
{ ren, ... }:
let
  inherit (ren.lib) and when;
in
{
  ren.aspects.unifi-gateway-unifi-terranix = {
    at = and [
      ren.kinds.environment
      (when ({ environment, ... }: environment.unifi != null))
    ];
    unifi-terranix =
      {
        environment,
        lib,
        bgp-peers ? [ ],
        port-forwards ? [ ],
        gateway-policies ? [ ],
        k3s-nodes ? [ ],
        ...
      }:
      let
        u = import ./_unifi-lib.nix { inherit lib; };
        unifi = environment.unifi;
        net = environment.networks.default;
        inherit (u) key recordsOf;
        renderNat = import ./_unifi-nat.nix {
          inherit lib key recordsOf;
          natRules = import ./_unifi-nat-rules.nix;
        };
        renderPolicies = import ./_unifi-policies.nix { inherit lib key; };
        renderBgp = import ./_unifi-bgp.nix { inherit lib; };
        renderPortForwards = import ./_unifi-portfwd.nix { inherit lib recordsOf; };
      in
      lib.foldl' lib.recursiveUpdate { } [
        (renderNat {
          env = environment.name;
          inherit (unifi) site networks;
          inherit (environment.dns) publicIPv4;
          forwards = port-forwards;
        })
        (renderPolicies {
          nodes = k3s-nodes;
          policies = gateway-policies;
        })
        (import ./_unifi-core.nix { inherit environment unifi; })
        {
          resource.unifi_bgp.${environment.name} = {
            inherit (unifi.bgp) enabled description;
            config = renderBgp {
              inherit (environment) name;
              inherit (net) cidr;
              asn = net.gatewayAsn;
              routerId = net.gatewayIp;
              peers = bgp-peers;
            };
            upload_file_name = unifi.bgp.uploadFileName;
          };
          resource.unifi_port_forward = renderPortForwards {
            env = environment.name;
            inherit (unifi) wans;
            forwards = port-forwards;
          };
        }
      ];
  };
}
