# Overlays: any host or user scope emits nixpkgs overlays; the host applies them once (hm uses the global pkgs).
{ ren, ... }:
{
  ren.channels.overlays = {
    fold = ren.lib.fold.list;
    to = e: ren.lib.upTo ren.kinds.host e; # the host itself, or the host a user is on
  };
}
