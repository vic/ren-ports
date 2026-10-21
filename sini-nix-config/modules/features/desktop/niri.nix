# desktop-niri: niri session (uwsm); compositor itself comes from elsewhere
{ ren, ... }:
{
  ren.aspects.desktop-niri = {
    includes = with ren.aspects; [ desktop-uwsm ];
    nixos = { };
  };
}
