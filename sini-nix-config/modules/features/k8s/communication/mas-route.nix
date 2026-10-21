# mas routes: its own host and the compatibility layer on the homeserver host.
{ ren, ... }:
let
  prefix = value: {
    path = {
      type = "PathPrefix";
      inherit value;
    };
  };
in
{
  ren.aspects.k8s-communication-matrix-mas.k8s-manifests =
    { cluster, ... }:
    {
      applications.matrix-authentication-service.resources.httpRoutes = {
        matrix-authentication-service.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "matrix-auth") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "matrix-auth"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "matrix-authentication-service";
                  port = 8080;
                }
              ];
            }
          ];
        };

        # MAS's compatibility layer for legacy clients, on the homeserver's own
        # host. The longer prefixes win over synapse-route.nix's /_matrix route.
        matrix-authentication-service-compat.spec = {
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
              matches = builtins.concatMap (
                version:
                map (op: prefix "/_matrix/client/${version}/${op}") [
                  "login"
                  "logout"
                  "refresh"
                ]
              ) [ "v3" "r0" ];
              backendRefs = [
                {
                  name = "matrix-authentication-service";
                  port = 8080;
                }
              ];
            }
          ];
        };
      };
    };
}
