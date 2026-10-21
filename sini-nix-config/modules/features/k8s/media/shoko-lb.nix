# Shoko internal-only LoadBalancer (see comment below); LB IP from cluster assignment shoko-internal.
{ ren, ... }:
{
  ren.aspects.k8s-media-shoko.k8s-manifests =
    { cluster, ... }:
    {
      applications.shoko.helm.releases.shoko.values = {
      # Internal-only LoadBalancer for off-cluster LAN callers (Jellyfin/Shokofin on uplink) that
      # only speak Shoko's native login and cannot satisfy the OIDC SecurityPolicy. LB IP is from
      # the private kubernetes-loadbalancers pool (BGP to uplink, not internet-routable); auth is
      # Shoko's own API key. externalTrafficPolicy=Local keeps the caller's real source IP.
      service.internal = {
        controller = "main";
        type = "LoadBalancer";
        externalTrafficPolicy = "Local";
        annotations."lbipam.cilium.io/ips" = ren.helpers.getAssignment cluster "shoko-internal";
        ports.http.port = 8111;
      };
      };
    };
}
