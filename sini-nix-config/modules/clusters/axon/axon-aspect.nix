# Cluster aspect: k8s services included at cluster scope (den.aspects.axon).
# Notes kept from den: gateway-api NOT included (envoy-gateway's gateway-crds-helm
# owns the Gateway API CRDs); tdarr left out (allocate against LLM GPU first).
{ ren, ... }:
{
  ren.aspects.axon = {
    at = ren.cluster.axon;
    includes = with ren.aspects; [
      k8s-hardware-amd-gpu-device-plugin
      k8s-hardware-gvisor
      k8s-bootstrap
      k8s-network-cilium
      k8s-network-cilium-bgp-resources
      k8s-network-coredns
      k8s-security-cert-manager
      k8s-security-cert-manager-xmsg-ca
      k8s-security-sops-secrets-operator
      k8s-argocd
      k8s-network-gateway-envoy-gateway
      k8s-network-gateway-host-upstreams
      k8s-storage-longhorn
      k8s-storage-csi-driver-nfs
      k8s-storage-volume-snapshots
      k8s-storage-cloudnative-pg
      k8s-monitoring-prometheus
      k8s-monitoring-metrics-server
      k8s-monitoring-loki
      k8s-monitoring-alloy
      k8s-monitoring-pg
      k8s-monitoring-grafana
      k8s-monitoring-ingest
      k8s-network-cilium-hubble-ui
      k8s-media-base
      k8s-media-pg
      k8s-media-api-keys
      k8s-media-prowlarr
      k8s-media-flaresolverr
      k8s-media-sonarr
      k8s-media-radarr
      k8s-media-lidarr
      k8s-media-whisparr
      k8s-media-bazarr
      k8s-media-sabnzbd
      k8s-media-qbittorrent
      k8s-media-unpackerr
      k8s-media-profilarr
      k8s-media-shoko
      k8s-media-network-policy
      k8s-media-glance
      k8s-media-dash
      k8s-media-romm
      k8s-media-komga
      k8s-communication-matrix-pg
      k8s-communication-matrix-synapse
      k8s-communication-matrix-mas
      k8s-communication-matrix-admin
      k8s-communication-matrix-element-web
      k8s-communication-matrix-tuwunel
      k8s-communication-smtp-relay
      k8s-ai-hindsight-pg
      k8s-ai-hindsight
      k8s-ai-genie-eval
      k8s-ai-model-egress
      k8s-ai-genie-guard
      k8s-ai-genie-experts-age-secrets # den genie-experts parent maps to its age-secrets child
      k8s-ai-searxng
      k8s-ai-llama-cpp
      k8s-dev-coder-pg
      k8s-dev-coder
      k8s-security-reflector
      k8s-storage-garage-secrets
      k8s-storage-garage-operator
      k8s-storage-garage-cluster
      k8s-storage-garage-network-policy
      k8s-storage-garage-routes
      k8s-storage-garage-ui
      k8s-storage-garage-sites
    ];
  };
}
