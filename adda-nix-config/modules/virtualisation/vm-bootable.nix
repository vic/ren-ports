# virtualisation: USB/VM installer images (tui = minimal, gui = graphical-base)
{ ren, ... }:
let
  installer = variant: {
    nixos =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/cd-dvd/installation-cd-${variant}.nix"
          # TODO: This is TTY only?
          # "${modulesPath}/virtualisation/qemu-vm.nix"
        ];
      };
  };
in
{
  # make USB/VM installers.
  ren.aspects.vm-bootable-tui = installer "minimal";
  ren.aspects.vm-bootable-gui = installer "graphical-base";
}
