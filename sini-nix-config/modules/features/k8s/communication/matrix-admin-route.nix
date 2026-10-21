# matrix-admin route, gateway OIDC policy, client secret and ingress CNP.
{ ren, ... }:
{
  ren.aspects.k8s-communication-matrix-admin.k8s-manifests =
    { cluster, ... }:
    {
      applications.matrix-admin.resources = {
        # One host: the UI at /, the Synapse client and admin APIs beside it, so
        # Ketesa's SSO login and admin calls stay same-origin behind the gateway.
        httpRoutes.matrix-admin.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "matrix-admin") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "matrix-admin"}-https";
            }
          ];
          rules = [
            {
              # Named: nixidy merges unnamed rules into one (rules is keyed by name).
              name = "synapse";
              matches = map (value: {
                path = {
                  type = "PathPrefix";
                  inherit value;
                };
              }) [ "/_synapse/admin" "/_synapse/client" "/_matrix" ];
              backendRefs = [
                {
                  name = "synapse";
                  port = 8008;
                }
              ];
            }
            {
              name = "ui";
              matches = [
                {
                  path = {
                    type = "PathPrefix";
                    value = "/";
                  };
                }
              ];
              backendRefs = [
                {
                  name = "matrix-admin";
                  port = 8080;
                }
              ];
            }
          ];
        };

        securityPolicies.matrix-admin-oidc.spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "matrix-admin";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "synapse-admin";
            clientID = "synapse-admin";
            clientSecret.name = "synapse-admin-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = false;
          };
        };
      };
    };
}
