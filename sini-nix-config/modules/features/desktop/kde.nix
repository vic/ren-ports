# desktop-kde: Plasma 6
{ ... }:
{
  ren.aspects.desktop-kde.nixos = {
    services.desktopManager.plasma6.enable = true;
  };
}
