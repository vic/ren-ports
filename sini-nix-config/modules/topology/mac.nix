# Macs: nix-darwin machines; users are listed in `users`.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.mac = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = s: lib.genAttrs (map (u: u.name) s.mac.users) (n: ren.user.${n});
    users = opt (t.listOf ren.kinds.user) [ ];
  };
}
