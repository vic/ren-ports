# Media-namespace Cilium network-policy matrix: the cross-service grant graph. Each media app emits only its
# baseline policies inline (gateway-ingress, postgres-egress, internet-egress). Cross-service edges owned by an
# app stay with it (unpackerr->*arr, profilarr->sonarr/radarr, *->qbittorrent ingress, media-pg->apiserver).
# This aspect closes the rest so EVERY media pod is selected by at least one ingress and one egress policy.
# Edge graph: _netpol-edges.nix; generators: _netpol-gen.nix; media-pg mesh + unpackerr lockdown: network-policy-pg.nix.
# NFS scratch/data are kubelet host-netns mounts, so no pod-level CNP governs them.
{ lib, ... }:
{
  ren.aspects.k8s-media-network-policy.k8s-manifests =
    { ... }:
    {
      applications.media-network-policy = {
        namespace = "media";
        resources.ciliumNetworkPolicies =
          let
            gen = import ./_netpol-gen.nix lib;
          in
          gen.egress // gen.ingress;
      };
    };
}
