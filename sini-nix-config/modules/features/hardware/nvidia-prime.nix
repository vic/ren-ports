{ ren, ... }:
{
  ren.aspects.hardware-gpu-nvidia-prime = {
    includes = with ren.aspects; [ hardware-gpu-nvidia ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        formatPciId =
          id: "PCI:" + (lib.strings.replaceStrings [ "." ] [ ":" ] (lib.strings.removePrefix "0000:" id));

        cardOf =
          vendor:
          lib.lists.findFirst (
            card: card.vendor.name == vendor
          ) null config.facter.report.hardware.graphics_card;

        nvidiaCard = cardOf "nVidia Corporation";
        amdCard = cardOf "ATI Technologies Inc";
        intelCard = cardOf "Intel Corporation";

        icard = if intelCard != null then intelCard else amdCard;
      in
      {
        hardware.nvidia = {
          powerManagement.finegrained = false; # TODO: Consider re-enabling later
          nvidiaPersistenced = false;
          prime = {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
            intelBusId = if intelCard != null then formatPciId intelCard.sysfs_bus_id else "";
            amdgpuBusId = if amdCard != null then formatPciId amdCard.sysfs_bus_id else "";
            nvidiaBusId = if nvidiaCard != null then formatPciId nvidiaCard.sysfs_bus_id else "PCI:1:0:0";
          };
          dynamicBoost.enable = true;
        };

        services.udev.packages = lib.optionals (icard != null) [
          (pkgs.writeTextDir "lib/udev/rules.d/61-gpu-offload.rules" ''
            SYMLINK=="dri/by-path/pci-${icard.sysfs_bus_id}-card", SYMLINK+="dri/igpu1"
            SYMLINK=="dri/by-path/pci-${nvidiaCard.sysfs_bus_id}-card", SYMLINK+="dri/dgpu1"
          '')
        ];
      };
  };
}
