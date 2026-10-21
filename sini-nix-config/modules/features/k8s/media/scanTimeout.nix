# SCAN_TIMEOUT (seconds) for RomM's background scan/rescan RQ job; job is killed when it elapses.
# Upstream default 14400 (4h). Raise for a large first-pass scan.
{ ren, lib, ... }:
{
  ren.kinds.cluster.k8s-media-romm-settings-scanTimeout = ren.lib.opt ren.helpers.types.positive 14400;
}
