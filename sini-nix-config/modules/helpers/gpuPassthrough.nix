# gpuPassthrough: { resolvePassthrough, toMicrovmDevices, mkVfioGate } (den virtualization/_gpu-passthrough-lib.nix).
# resolvePassthrough intents facter -> [ { busId; } ]; toMicrovmDevices recs -> microvm.devices; mkVfioGate pkgs recs -> script.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  tagSpec.nvidia.vendorName = "nVidia Corporation";
  matchDevices =
    tag: facter:
    lib.optional (firstOf tag facter.hardware.graphics_card != null) { busId = (firstOf tag facter.hardware.graphics_card).sysfs_bus_id; }
    ++ lib.optional (firstOf tag facter.hardware.sound != null) { busId = (firstOf tag facter.hardware.sound).sysfs_bus_id; };
  firstOf =
    tag:
    lib.lists.findFirst (
      c: c.vendor.name == (tagSpec.${tag} or (throw "gpu-passthrough: unknown passthrough tag '${tag}'")).vendorName
    ) null;
in
{
  ren.helpers.gpuPassthrough = {
    resolvePassthrough = intents: facter: lib.concatMap (tag: matchDevices tag facter) intents;
    toMicrovmDevices = map (d: {
      bus = "pci";
      path = d.busId;
    });
    mkVfioGate =
      pkgs: recs:
      pkgs.writeScript "check-vfio-${builtins.replaceStrings [ ":" ] [ "-" ] (lib.head recs).busId}.sh" ''
        #! ${pkgs.runtimeShell} -e
        content=$(< /sys/bus/pci/drivers/vfio-pci/${(lib.head recs).busId}/enable)
        echo "VFIO enable check: device ${(lib.head recs).busId} enable=$content" | ${pkgs.systemd}/bin/systemd-cat -t vfio-check -p info
        [ "$content" == "0" ]
      '';
  };
}
