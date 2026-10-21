# oidcIssuerFor cluster clientID -> kanidm's OIDC issuer URL for that client.
{ ren, ... }:
{
  ren.helpers.oidcIssuerFor =
    cluster: id: "https://${ren.helpers.clusterDomainFor cluster "kanidm"}/oauth2/openid/${id}";
}
