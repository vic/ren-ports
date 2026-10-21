{ ren, ... }:
{
  ren.aspects.kube-tools = {
    includes = with ren.aspects; [
      dev-k8s-core
      dev-k8s-dev
      dev-k8s-helm
      dev-k8s-observability
      dev-k8s-plugins
      dev-k8s-security
      dev-k8s-tui
      dev-k8s-utils
    ];
  };
}
