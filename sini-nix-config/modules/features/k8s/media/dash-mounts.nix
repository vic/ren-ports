# Dash mounts: external (raw) ConfigMap "dash-config" mounted by name, one file per subPath into
# /app/config. Stateless: config arrives via the ConfigMap (dash-config.nix), no config PVC.
{ ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { ... }:
    {
      applications.dash.helm.releases.dash.values = {
        persistence.config = {
          type = "configMap";
          name = "dash-config";
          # One mount per config file, in attr-name-sorted order
          # (lib.attrNames over the config-file set: bookmarks, kubernetes,
          # services, settings, widgets).
          globalMounts = [
            {
              path = "/app/config/bookmarks.yaml";
              subPath = "bookmarks.yaml";
              readOnly = true;
            }
            {
              path = "/app/config/kubernetes.yaml";
              subPath = "kubernetes.yaml";
              readOnly = true;
            }
            {
              path = "/app/config/services.yaml";
              subPath = "services.yaml";
              readOnly = true;
            }
            {
              path = "/app/config/settings.yaml";
              subPath = "settings.yaml";
              readOnly = true;
            }
            {
              path = "/app/config/widgets.yaml";
              subPath = "widgets.yaml";
              readOnly = true;
            }
          ];
        };
      };
    };
}
