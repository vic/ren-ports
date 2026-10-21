# desktop-xwayland
{ ... }:
{
  ren.aspects.desktop-xwayland.nixos = {
    programs.xwayland.enable = true;
  };
}
