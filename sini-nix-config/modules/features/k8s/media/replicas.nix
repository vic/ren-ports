# RomM Deployment replica count (den: romm.settings.replicas). Does not speed a single scan
# (SCAN_WORKERS); replicas > 1 need an RWX userdata volume (romm-userdata PVC is RWO). Kept at 1.
{ ren, lib, ... }:
{
  ren.kinds.cluster.k8s-media-romm-settings-replicas = ren.lib.opt ren.helpers.types.positive 1;
}
