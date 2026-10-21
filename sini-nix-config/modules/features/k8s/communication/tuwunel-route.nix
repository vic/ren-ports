# tuwunel route (whole host: client/federation APIs, admin is in-band) and CNPs.
{ ren, ... }:
let
  tcp = p: {
    port = toString p;
    protocol = "TCP";
  };
  policy = description: rule: {
    spec = {
      inherit description;
      endpointSelector.matchLabels."app.kubernetes.io/name" = "tuwunel";
    }
    // rule;
  };
in
{
  ren.aspects.k8s-communication-matrix-tuwunel.k8s-manifests =
    { cluster, ... }:
    {
      applications.tuwunel.resources = {
        httpRoutes.tuwunel.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "tuwunel") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "gen-wtf-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "tuwunel";
                  port = 8008;
                }
              ];
            }
          ];
        };

        ciliumNetworkPolicies = {
          allow-gateway-ingress-tuwunel = policy "Allow Envoy Gateway proxies to reach tuwunel." {
            ingress = [
              {
                fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
                toPorts = [ { ports = [ (tcp 8008) ]; } ];
              }
            ];
          };
          # 443: kanidm and federation peers; 8448: peers without delegation.
          allow-internet-egress-tuwunel = policy "Allow tuwunel to reach kanidm and federation peers." {
            egress = [
              {
                toEntities = [ "world" ];
                toPorts = [
                  {
                    ports = [
                      (tcp 443)
                      (tcp 8448)
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
    };
}
