# Thunderbolt network hardware support.
#
# Auto-discovers thunderbolt controllers from facter and creates systemd.network.links
# with predictable interface names derived from PCI topology plus tb<N> aliases.
{ ... }:
{
  ren.aspects.hardware-thunderbolt-network = {
    nixos =
      { config, lib, ... }:
      let
        # Sorted by PCI bus ID for deterministic interface numbering
        thunderboltControllers = lib.sort (a: b: a.sysfs_bus_id < b.sysfs_bus_id) (
          lib.filter (c: c.driver == "thunderbolt") config.facter.report.hardware.usb_controller
        );

        parseBusId = busId: {
          busDec = toString (lib.fromHexString (lib.elemAt (lib.splitString ":" busId) 1));
          slotDec = toString (
            lib.fromHexString (lib.elemAt (lib.splitString "." (lib.elemAt (lib.splitString ":" busId) 2)) 0)
          );
          func = lib.elemAt (lib.splitString "." (lib.elemAt (lib.splitString ":" busId) 2)) 1;
        };

        mkPredictableName =
          busId:
          "enp${(parseBusId busId).busDec}s${(parseBusId busId).slotDec}f${(parseBusId busId).func}";

        mkLink = idx: controller: {
          name = "20-thunderbolt-port-${toString idx}";
          value = {
            matchConfig = {
              Path = "pci-${controller.sysfs_bus_id}";
              Driver = "thunderbolt-net";
            };
            linkConfig = {
              Name = mkPredictableName controller.sysfs_bus_id;
              Alias = "tb${toString idx}";
              AlternativeName = "tb${toString idx}";
              # Segmentation/receive offloads OFF on the fabric: tbnet
              # GRO/TSO superframes exceed the device MTU and cilium's
              # legacy host-routing path checks aggregate length, answering
              # each with ICMP frag-needed (host<->pod bulk stalls). These
              # settings MUST live here: udev applies exactly one .link
              # file per device and these per-port files win the match
              # (a separate 20-thunderbolt.link never applied — found when
              # a cable reseat re-enumerated the device with offloads on).
              GenericReceiveOffload = false;
              GenericSegmentationOffload = false;
              TCPSegmentationOffload = false;
            };
          };
        };
      in
      lib.mkIf (thunderboltControllers != [ ]) {
        boot = {
          kernelParams = [ "pcie=pcie_bus_perf" ];
          kernelModules = [
            "thunderbolt"
            "thunderbolt-net"
          ];
          # End-to-end flow control off: with it on, the receiving NHI flags
          # every IP packet of 227-230 bytes (a 253-256 byte ring frame) as a
          # CRC error and drops it, on every link and in both directions
          # (AMD Pink Sardine 1022:1668). Lost DNS replies of that size stalled
          # Go resolvers for 5 s. Measured with e2e=0 on one end: no loss and
          # no CRC errors at those sizes; the e2e=1 control link kept 70% loss.
          extraModprobeConfig = "options thunderbolt_net e2e=0";
        };

        systemd.network.links = lib.listToAttrs (lib.imap0 mkLink thunderboltControllers);
      };
  };
}
