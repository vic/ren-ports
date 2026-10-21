# oidcProviderFor cluster clientID -> Envoy Gateway OIDC provider with kanidm's fixed endpoints
# (den schema/cluster.nix methods.secrets; stating both endpoints skips the controller's discovery fetch).
{ ren, ... }:
let
  kanidm = cluster: ren.helpers.clusterDomainFor cluster "kanidm";
in
{
  ren.helpers.oidcProviderFor = cluster: clientID: {
    issuer = ren.helpers.oidcIssuerFor cluster clientID;
    authorizationEndpoint = "https://${kanidm cluster}/ui/oauth2";
    tokenEndpoint = "https://${kanidm cluster}/oauth2/token";
  };
}
