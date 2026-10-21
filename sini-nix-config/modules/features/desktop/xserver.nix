# desktop-xserver: X server + libinput, us layout
{ ... }:
{
  ren.aspects.desktop-xserver.nixos = {
    services = {
      libinput.enable = true;
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };
    };
  };
}
