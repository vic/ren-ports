# garage-ui exposure: HTTPRoute + OIDC SecurityPolicy + Secrets + egress CNP.
# Same aspect as garage-ui.nix.
{ ren, ... }:
{
  ren.aspects.k8s-storage-garage-ui.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.garage.resources = {
        # garage.json64.dev rides the existing *.json64.dev wildcard listener
        # (json64-dev-https) - no new cert.
        httpRoutes.garage-ui.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "garage-ui") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "garage-ui"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "garage-ui";
                  port = 80;
                }
              ];
            }
          ];
        };

        securityPolicies."garage-ui-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "garage-ui";
            }
          ];

          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "garage-ui";
            clientID = "garage-ui";
            clientSecret.name = "garage-ui-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets = {
          garage-ui-oidc-client-secret = {
            type = "Opaque";
            stringData.client-secret = config.age.secrets.garage-ui-oidc-client-secret.sopsRef;
          };

          # Same name the chart used, so the live Secret is replaced in place
          # rather than renamed. Its VALUE changes once on this deploy (active UI
          # sessions drop), then never again.
          garage-ui-jwt-key = {
            type = "Opaque";
            stringData."jwt-key.pem" = config.age.secrets.garage-ui-jwt-key.sopsRef;
          };
        };

        # garage-ui drives the Garage admin API only (3903). Once any egress
        # policy selects these pods they default-deny egress; DNS is covered by
        # coredns.nix's cluster-wide egress grant.
        ciliumNetworkPolicies.allow-garage-ui-admin-egress.spec = {
          description = "garage-ui to the Garage admin API (3903).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "garage-ui";
          egress = [
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/name" = "garage"; } ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "3903";
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
