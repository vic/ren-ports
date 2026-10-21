# channels n-z (overlays family): den quirks nixpkgs-overlays, stylix-hm.
{ ren, lib, ... }:
{
  # any -> nearest machine; `os` forwards to nixos or darwin (layout sec 2).
  ren.channels.nixpkgs-overlays = {
    fold = ren.lib.fold.list;
    to = e: ren.lib.upTo ren.kinds.machine e;
    into = { ... }: o: { os.nixpkgs.overlays = lib.unique o; };
  };

  # user -> user: firefox stylix cfg fragments, merged into the hm stylix targets.
  ren.channels.stylix-hm = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e;
    into = { ... }: f: { homeManager.stylix = lib.mkMerge f; };
  };
}
