# element-web route on the default-gateway and its ingress CNP.
{ ren, ... }:
{
  ren.aspects.k8s-communication-matrix-element-web.k8s-manifests =
    { cluster, ... }:
    {
      applications.element-web.resources = {
        httpRoutes.element-web.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "chat") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "chat"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "element-web";
                  port = 8080;
                }
              ];
            }
          ];
        };

        ciliumNetworkPolicies.allow-gateway-ingress-element-web.spec = {
          description = "Allow Envoy Gateway proxies to reach Element Web.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "element-web";
          ingress = [
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8080";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };
      };
    };
}
