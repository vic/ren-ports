# virtualisation: VM flavours, each a bootable installer image
{ ren, ... }:
{
  ren.aspects.vm-gui.includes = [
    ren.aspects.vm-bootable-gui
    # addax.xfce-desktop
  ];

  ren.aspects.vm-tui.includes = [
    ren.aspects.vm-bootable-tui
  ];
}
