# matrix-admin client secret and ingress CNP.
_:
{
  ren.aspects.k8s-communication-matrix-admin.k8s-manifests =
    { config, ... }:
    {
      applications.matrix-admin.resources = {
        secrets.synapse-admin-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.synapse-admin-oidc-client-secret.sopsRef;
        };

        ciliumNetworkPolicies.allow-gateway-ingress-matrix-admin.spec = {
          description = "Allow Envoy Gateway proxies to reach the Ketesa UI.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "matrix-admin";
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
