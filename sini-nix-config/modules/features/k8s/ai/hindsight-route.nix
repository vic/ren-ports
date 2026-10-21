# The control-plane UI, behind the gateway's kanidm OIDC. kanidm maps only
# `admins` to the `hindsight` client (kanidm.nix), so no one else can
# obtain a session; the gateway's admission is the authorization.
{ ren, lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { cluster, ... }:
    {
      applications.hindsight.resources = {
        httpRoutes.hindsight.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "hindsight") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "hindsight"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "hindsight-cp";
                  port = shared.cpPort;
                }
              ];
            }
          ];
        };

        securityPolicies."hindsight-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "hindsight";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "hindsight";
            clientID = "hindsight";
            clientSecret.name = "hindsight-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
          };
        };
      };
    };
}
