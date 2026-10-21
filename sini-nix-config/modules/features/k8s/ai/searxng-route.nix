# searxng: settings Secret, internal LoadBalancer, and the OIDC-gated gateway route.
{ ren, ... }:
let
  inherit (import ./_searxng-shared.nix) name port pod;
  inherit (import ./_searxng-settings.nix) engines settingsFor;
in
{
  ren.aspects.k8s-ai-searxng.k8s-manifests =
    { cluster, config, ... }:
    let
      host = ren.helpers.clusterDomainFor cluster "search";
    in
    {
      applications.${name}.resources = {
        secrets.${name}.stringData = {
          "settings.yml" = builtins.toJSON (settingsFor engines "https://${host}/");
          secret-key = config.age.secrets.searxng-secret-key.sopsRef;
        };

        services."${name}-internal" = {
          metadata.annotations."lbipam.cilium.io/ips" = ren.helpers.getAssignment cluster "searxng-internal";
          spec = {
            type = "LoadBalancer";
            externalTrafficPolicy = "Local";
            selector = pod;
            ports = [
              {
                name = "http";
                inherit port;
                targetPort = port;
              }
            ];
          };
        };

        httpRoutes.${name}.spec = {
          hostnames = [ host ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "search"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  inherit name port;
                }
              ];
            }
          ];
        };

        securityPolicies."${name}-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              inherit name;
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster name;
            clientID = name;
            clientSecret.name = "${name}-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
          };
        };

        secrets."${name}-oidc-client-secret" = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.searxng-oidc-client-secret.sopsRef;
        };
      };
    };
}
