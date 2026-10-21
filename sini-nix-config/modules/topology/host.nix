# Hosts: NixOS machines; users come from the group-closure helper, guests from `guests`.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.host = {
    is = ren.kinds.machine;
    below = [
      ren.kinds.user
      ren.kinds.guest
    ];
    spawns = {
      user = s: ren.helpers.usersOf s.host;
      guest = s: lib.genAttrs (map (g: g.name) s.host.guests) (n: ren.guest.${n});
    };
    guests = opt (t.listOf ren.kinds.guest) [ ];
  };
}
