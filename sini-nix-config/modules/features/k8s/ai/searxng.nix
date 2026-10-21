# searxng — the fleet's metasearch service. Three ways in, each on an existing
# convention, and nothing public:
#
#   genie tier 1   in-cluster ClusterIP, http://searxng.search.svc.cluster.local:8080
#                  (genie-agent src/tier1/web.ts: GET <url>/search?q=…&format=json)
#   fleet hosts    the internal LoadBalancer `searxng-internal` (axon.nix assignments),
#                  BGP-advertised to the LAN and not internet-routable — the
#                  hindsight/shoko idiom for headless API clients, which the
#                  OIDC gateway would turn away
#   people         https://search.<domain> on the default gateway behind kanidm
#                  OIDC, granted to `search.access` (every user)
#
# Chart: littleoffice/searxng (rootless, read-only root, no init containers), image
# pinned by the image updater. Its settings.yml and secret_key come only from a
# Secret it is pointed at (searxng-route.nix writes it): settings.yml is no secret,
# so it rides as plain stringData; secret-key is a generated token.
#
# Engines: SearXNG's defaults narrowed with `keep_only` to keyless engines that
# answer what the fleet asks, from the cluster's egress address (the site's
# residential IP, not a datacenter one). Upstream ships google and bing `disabled`
# and mojeek and startpage `inactive` (never loaded, which `keep_only` alone does
# not undo), so each is switched on in _searxng-settings.nix.
#   google, bing, duckduckgo, mojeek  general web results, four independent indexes
#   startpage                         Google's results through Startpage's proxy;
#                                     solves its Anubis proof-of-work (difficulty 4,
#                                     ~65k sha256, token cached 240s), which upstream
#                                     leaves off as a public-instance CPU precaution
#   wikipedia                         reference pages (English only: one host)
#   github, stackoverflow             code and Q&A, moved into `general` so a plain
#                                     query reaches them; API clients send no categories
# Not kept: brave (search.brave.com answers this address 429 even to a plain
# request, measured from the pod), qwant. google stays on while it is broken
# upstream (searxng#6835: /wml/search answers 403); suspended, it costs one
# request a day and returns on its own with the fix.
#
# Limiter off and no Valkey: every path in is private and admitted by the policies
# in searxng-net.nix, and the API clients are the fleet's own.
{ ren, ... }:
let
  inherit (import ./_searxng-shared.nix) namespace name port;
  inherit (import ./_searxng-settings.nix) engines settingsFor;
in
{
  ren.aspects.k8s-ai-searxng = {
    service-domains = [ "search" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "search" ];

    k8s-manifests =
      {
        cluster,
        charts,
        images,
        ...
      }:
      {
        applications.${name} = {
          inherit namespace;
          createNamespace = true;

          helm.releases.${name} = {
            chart = charts.littleoffice.searxng;
            values = {
              # The chart cannot hash a settings Secret it does not write, so
              # editing that Secret would not roll the pod (SearXNG reads its
              # settings once, at boot). It is written here, so hash it here.
              commonAnnotations."checksum/settings" = builtins.hashString "sha256" (
                builtins.toJSON (settingsFor engines "https://${ren.helpers.clusterDomainFor cluster "search"}/")
              );
              image = {
                registry = "docker.io";
                inherit (images."searxng/searxng") repository digest;
                tag = "";
              };
              # A metasearch proxy holds no state; one replica until load says otherwise.
              replicaCount = 1;
              podDisruptionBudget.enabled = false;
              searxng = {
                existingSecret = name;
                existingSettingsSecret = name;
                inherit port;
                limiter.enabled = false;
              };
              service.port = port;
              valkey.enabled = false;
              # A `helm test` hook Pod; ArgoCD would apply it as a plain Pod.
              tests.enabled = false;
              # Cilium policies instead: the chart's NetworkPolicies are
              # CIDR-only, and engine egress needs toFQDNs.
              networkPolicy.enabled = false;
            };
          };
        };
      };
  };
}
