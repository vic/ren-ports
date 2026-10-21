# synapse apex .well-known delegation documents, answered by Envoy HTTPRouteFilters.
{ ren, lib, ... }:
{
  ren.aspects.k8s-communication-matrix-synapse.k8s-manifests =
    { cluster, ... }:
    {
      applications.synapse = {
    # Matrix delegation for server_name json64.dev, answered by Envoy on the
    # apex listener (json64-dev-apex-https; the domain's web.apex).
    objects = lib.mapAttrsToList (name: body: {
      apiVersion = "gateway.envoyproxy.io/v1alpha1";
      kind = "HTTPRouteFilter";
      metadata = {
        name = "matrix-well-known-${name}";
        namespace = "matrix";
      };
      spec.directResponse = {
        statusCode = 200;
        contentType = "application/json";
        body = {
          type = "Inline";
          inline = builtins.toJSON body;
        };
        # Required by the client spec; harmless on the server document.
        header.set = [
          {
            name = "Access-Control-Allow-Origin";
            value = "*";
          }
        ];
      };
    }) {
      server."m.server" = "${ren.helpers.clusterDomainFor cluster "matrix"}:443";
      client."m.homeserver".base_url = "https://${ren.helpers.clusterDomainFor cluster "matrix"}";
    };
      };
    };
}
