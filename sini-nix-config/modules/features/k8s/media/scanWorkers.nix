# SCAN_WORKERS: concurrent per-ROM identifications within a scan job (asyncio concurrency over
# metadata-provider I/O, not OS processes). Upstream default 1 (serial); bounded by provider rate limits.
{ ren, lib, ... }:
{
  ren.kinds.cluster.k8s-media-romm-settings-scanWorkers = ren.lib.opt ren.helpers.types.positive 1;
}
