# PRODUCE: a background GPU claim per guest with a non-empty passthrough intent.
# windows-vfio's qemu hook consumes these to preempt the microvm during interactive Windows sessions.
{ lib, ... }:
{
  ren.aspects.virtualization-microvm-host-gpu-claims.gpu-claims =
    { host, ... }:
    lib.concatMap (
      vm:
      lib.optional (vm.microvm.passthrough != [ ]) {
        device = lib.head vm.microvm.passthrough;
        priority = "background";
        kind = "microvm";
        unit = "microvm@${vm.name}.service";
      }
    ) host.guests;
}
