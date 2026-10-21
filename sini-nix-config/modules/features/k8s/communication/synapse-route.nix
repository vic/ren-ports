# synapse routes: client/federation APIs and the apex .well-known (filters in synapse-wellknown.nix).
{ ren, ... }:
{
  ren.aspects.k8s-communication-matrix-synapse.k8s-manifests =
    { cluster, ... }:
    {
      applications.synapse = {
        resources = {
          # Only the client and federation APIs are public. /_synapse/admin is
          # intentionally absent.
          httpRoutes.synapse.spec = {
            hostnames = [ (ren.helpers.clusterDomainFor cluster "matrix") ];
            parentRefs = [
              {
                name = "default-gateway";
                namespace = "gateways";
                sectionName = "${ren.helpers.domainForResource cluster "matrix"}-https";
              }
            ];
            rules = [
              {
                matches = [
                  {
                    path = {
                      type = "PathPrefix";
                      value = "/_matrix";
                    };
                  }
                  {
                    path = {
                      type = "PathPrefix";
                      value = "/_synapse/client";
                    };
                  }
                ];
                backendRefs = [
                  {
                    name = "synapse";
                    port = 8008;
                  }
                ];
                # Above the 30s long-poll clients ask /sync for; Envoy's 15s route
                # default cuts every one short.
                timeouts.request = "120s";
              }
            ];
          };

          httpRoutes.matrix-well-known.spec = {
            hostnames = [ "json64.dev" ];
            parentRefs = [
              {
                name = "default-gateway";
                namespace = "gateways";
                sectionName = "${ren.helpers.domainForResource cluster "matrix"}-apex-https";
              }
            ];
            rules = map (doc: {
              # Named: nixidy merges unnamed rules into one (rules is keyed by name).
              name = doc;
              matches = [
                {
                  path = {
                    type = "Exact";
                    value = "/.well-known/matrix/${doc}";
                  };
                }
              ];
              filters = [
                {
                  type = "ExtensionRef";
                  extensionRef = {
                    group = "gateway.envoyproxy.io";
                    kind = "HTTPRouteFilter";
                    name = "matrix-well-known-${doc}";
                  };
                }
              ];
            }) [ "server" "client" ];
          };
        };
      };
    };
}
