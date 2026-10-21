# Media network-policy generators over the edge graph (_netpol-edges.nix). Returns { egress, ingress }.
#
# Cilium: default-deny is per-endpoint AND per-direction. Egress is already open to in-cluster peers
# (CiliumClusterwideNetworkPolicy allow-internal-egress), but the per-source egress edges are emitted anyway so the
# grant graph stays explicit and correct if that is ever tightened. Ingress is the real work: routed apps are in
# ingress default-deny and reject in-namespace callers without these edges.
lib:
let
  g = import ./_netpol-edges.nix lib;
  podSel = name: { matchLabels."app.kubernetes.io/name" = name; };
  toPortsTcp = port: [
    {
      ports = [
        {
          port = toString port;
          protocol = "TCP";
        }
      ];
    }
  ];
  uniq = lib.lists.unique;

  # qbittorrent INGRESS is owned by qbittorrent.nix (aggregates *arr + prowlarr + unpackerr); the *arr ->
  # qbittorrent egress side is ours. So: egress for ALL edges, ingress skips qbittorrent targets.
  ingressTargets = builtins.filter (t: t != "qbittorrent") (uniq (map (e: e.to) g.edges));

  # Dashboards consume the *arr + sabnzbd APIs (flaresolverr has only prowlarr as caller).
  dashboardConsumes = g.arrs ++ [ "sabnzbd" ];

  # Helper pods whose EGRESS half lives in their owning app file still need the arr-side ingress allow HERE.
  # Benign asymmetry: profilarr egresses only to sonarr/radarr, so its lidarr/whisparr ingress grants are
  # egress-blocked dead allows (harmless). unpackerr is symmetric.
  arrHelperSources = [
    "unpackerr"
    "profilarr"
  ];
in
{
  # One egress policy per source, one toEndpoints/toPorts pair per distinct target so ports stay exact.
  egress = builtins.listToAttrs (
    map (
      src:
      lib.nameValuePair "allow-media-egress-${src}" {
        spec = {
          description = "Allow ${src} to reach its in-namespace media targets.";
          endpointSelector = podSel src;
          egress = map (t: {
            toEndpoints = [ (podSel t) ];
            toPorts = toPortsTcp g.ports.${t};
          }) (uniq (map (e: e.to) (builtins.filter (e: e.from == src) g.edges)));
        };
      }
    ) (uniq (map (e: e.from) g.edges))
  );

  # One ingress policy per target: in-namespace sources + pre-declared dashboards + arr helper sources.
  ingress = builtins.listToAttrs (
    map (
      tgt:
      let
        dashSources = lib.optionals (builtins.elem tgt dashboardConsumes) g.dashboards;
      in
      lib.nameValuePair "allow-media-ingress-${tgt}" {
        spec = {
          description = "Allow in-namespace callers${
            lib.optionalString (dashSources != [ ]) " + dashboards"
          } to reach ${tgt}:${toString g.ports.${tgt}}.";
          endpointSelector = podSel tgt;
          ingress = [
            {
              fromEndpoints = map podSel (
                uniq (map (e: e.from) (builtins.filter (e: e.to == tgt) g.edges))
                ++ dashSources
                ++ lib.optionals (builtins.elem tgt g.arrs) arrHelperSources
              );
              toPorts = toPortsTcp g.ports.${tgt};
            }
          ];
        };
      }
    ) ingressTargets
  );
}
