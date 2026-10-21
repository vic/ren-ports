# Dash (gethomepage): utility dashboard for the media stack. Named "dash" (not "homepage") to avoid
# colliding with the uplink host's homepage.json64.dev (services.web.homepage); Kanidm client is "dash".
# No nixhelm gethomepage chart: bjw-s app-template on ghcr.io/gethomepage/homepage.
# Static services.yaml (no HTTPRoute auto-discovery); widget keys via {{HOMEPAGE_VAR_*}} env from
# media-arr-api-keys. qBittorrent widget omitted: WebUI is OIDC/loopback-locked, homepage cannot auth.
# Config ConfigMap + mounts in dash-config.nix, RBAC in dash-rbac.nix, CNPs in dash-net.nix,
# route/OIDC in dash-route.nix. Image: rolling `latest`, digest-pinned in images/gethomepage/homepage.
{ ren, ... }:
{
  ren.aspects.k8s-media-dash = {
    service-domains = [ "dash" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "dash" ];

# the name is deterministic for the binding subject), point the controller at it
# (controllers.main.serviceAccount.name = "dash"), and grant a ClusterRole (get/
# list/watch on namespaces, pods, nodes, services, ingresses, gateway-api
# httproutes, and metrics) via a ClusterRoleBinding.
#
# == Config delivery (raw ConfigMap) ==
# The config files are delivered as a RAW ConfigMap "dash-config" (not via the
# chart's `configMaps` values) so their data bypasses app-template's Helm `tpl`
# pass — that pass would try to evaluate homepage's `{{HOMEPAGE_VAR_*}}`
# substitution tokens as Helm template calls and fail (the same `tpl` foot-gun
# qbittorrent.nix documents). The ConfigMap is mounted by name, one file per
# subPath, via persistence.config.
#
# == Networking ==
# Egress (mirrors the pre-declared dashboard ingress edges in network-policy.nix):
#   - gateway-ingress baseline (DNS is coredns.nix's cluster-wide egress grant).

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.dash = {
          namespace = "media";

          helm.releases.dash = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                containers.main = {
                  image = {
                    inherit (images."gethomepage/homepage") repository digest;
                  };
                  # baseEnv + HOMEPAGE_ALLOWED_HOSTS (host-header guard; must match
                  # the public hostname the gateway forwards) + the *arr/sabnzbd
                  # API key env (HOMEPAGE_VAR_<APP>_KEY <- media-arr-api-keys.<app>,
                  # referenced in services.yaml as {{HOMEPAGE_VAR_<APP>_KEY}};
                  # qbittorrent omitted, see header).
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    HOMEPAGE_ALLOWED_HOSTS = "dash.json64.dev";
                    HOMEPAGE_VAR_LIDARR_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "lidarr";
                    };
                    HOMEPAGE_VAR_RADARR_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "radarr";
                    };
                    HOMEPAGE_VAR_SABNZBD_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "sabnzbd";
                    };
                    HOMEPAGE_VAR_SONARR_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "sonarr";
                    };
                  };
                  envFrom = [ ];
                };

                # Bind the pod to our explicit ServiceAccount (created as a raw
                # resource so its name is deterministic for the ClusterRoleBinding
                # subject below) and mount its token — homepage's cluster-mode
                # discovery authenticates to the kube-apiserver with it (the chart
                # defaults automount to false).
                serviceAccount.name = "dash";
                pod.automountServiceAccountToken = true;
              };

              service.main = {
                controller = "main";
                ports.http.port = 3000; # gethomepage default HTTP port
              };

            };
          };
        };
      };
  };
}
