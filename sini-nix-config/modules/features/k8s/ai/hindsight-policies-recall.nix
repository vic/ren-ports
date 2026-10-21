# hindsight ingress policies, part 2: genie tier-1 recall, gateway to the CP, LAN.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
  inherit (shared) port cpPort tcp;
  dataplane = {
    "app.kubernetes.io/name" = "hindsight";
  };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests.applications.hindsight.resources.ciliumNetworkPolicies = {
    # genie tier-1 recalls from the genie banks and may do nothing else
    # here. Selected by namespace and service account, which Cilium sets
    # from the pod spec and a pod cannot claim (see model-egress.nix). The
    # HTTP rule sends this port through Envoy, which answers 403 to any
    # other method or path from this identity, whatever token it holds.
    allow-genie-tier1-recall-hindsight.spec = {
      description = "Allow genie tier-1 to recall from the genie banks on 8888 (HTTP rule: recall and the read-only GETs its client makes).";
      endpointSelector.matchLabels = dataplane;
      ingress = [
        {
          fromEndpoints = [
            {
              matchLabels = {
                "k8s:io.kubernetes.pod.namespace" = "genie";
                "k8s:io.cilium.k8s.policy.serviceaccount" = "genie-tier1";
              };
            }
          ];
          toPorts = [
            {
              ports = (lib.head (tcp [ port ])).ports;
              rules.http = [
                {
                  method = "POST";
                  path = "/v1/default/banks/(genie|genie-memory)/memories/recall";
                }
                {
                  method = "GET";
                  path = "/v1/default/banks/(genie|genie-memory)/(profile|config|memories/list)";
                }
              ];
            }
          ];
        }
      ];
    };

    # The control plane's only ingress: the gateway's proxies, which admit
    # a request only after the admin-only OIDC. Being the only rule, it
    # puts the CP in ingress default-deny for everything else.
    allow-gateway-ingress-hindsight-cp.spec = {
      description = "Allow only Envoy Gateway proxies to reach the hindsight control plane UI (3000).";
      endpointSelector.matchLabels."app.kubernetes.io/name" = "hindsight-cp";
      ingress = [
        {
          fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
          toPorts = tcp [ cpPort ];
        }
      ];
    };

    # Off-cluster LAN callers (workstations, uplink) reach the bank over
    # the internal LoadBalancer, bypassing the gateway. The whole
    # private 10/8 range rather than a per-host pin: it is portable, the
    # LB address is RFC1918 and not internet-routable, and it covers both
    # the externalTrafficPolicy=Local source (the caller's real IP) and
    # any node SNAT. Mirrors allow-lan-ingress-shoko.
    allow-lan-ingress-hindsight.spec = {
      description = "Allow private-LAN clients to reach hindsight on 8888 over the internal LoadBalancer.";
      endpointSelector.matchLabels = dataplane;
      ingress = [
        {
          fromCIDR = [ "10.0.0.0/8" ];
          toPorts = tcp [ port ];
        }
      ];
    };
  };
}
