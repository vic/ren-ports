# machines: the abstract `machine` kind and its kinds (host, guest, mac, home, droid); the user kind.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe same;
  t = lib.types;
  # a machine's users are data on the machine (old `swarselsystems.mainUser`)
  usersOf = m: builtins.listToAttrs (map (u: { inherit (u) name; value = u; }) m.users);
in
{
  ren.helpers.usersOf = usersOf;
  # old specialArg `type`: the machine kind as the old host directory name
  ren.helpers.typeOf =
    m:
    if ren.host ? ${m.name} || ren.guest ? ${m.name} then
      "nixos"
    else if ren.mac ? ${m.name} then
      "darwin"
    else if ren.home ? ${m.name} then
      "home"
    else
      "android";

  ren.kinds.user.login = maybe t.str; # null: the instance name is the login

  ren.kinds.machine = {
    system = ren.kinds.system;
    users = opt (t.listOf ren.kinds.user) [ ren.user.swarsel ];
    configName = maybe t.str; # null: the instance name (utility hosts: one instance per arch)
    fleet = opt ren.kinds.fleet ren.fleet.swarsel;
    nixpkgs = maybe t.raw; # null: inputs.nixpkgs (the sandbox host: nixpkgs-sandbox)
  };

  # NixOS machines (old hosts/nixos/<arch>/<name> and hosts/utility/<name>)
  ren.kinds.host = {
    is = ren.kinds.machine;
    below = [
      ren.kinds.user
      ren.kinds.guest
    ];
    spawns = {
      user = s: usersOf s.host;
      # old `guests = lib.mkIf (!minimal ...)`: the minimal build has no guests
      guest = s: if s.variant.minimal then { } else lib.filterAttrs (_: g: same g.on s.host) ren.guest;
    };
  };

  # MicroVM guests (old hosts/nixos/<arch>/<host>/guests/<name>, node `<host>-<name>`)
  ren.kinds.guest = {
    is = ren.kinds.host; # declares its own `below`: no guest in a guest
    below = [ ]; # no home-manager in guests (old isMicroVM)
    on = ren.kinds.host;
    guestName = t.str; # the name inside its host; the instance name is the old node name `<host>-<guest>`
    withZfs = opt t.bool false;
    eternorPaths = opt (t.listOf t.str) [ ];
  };

  # nix-darwin machines (old hosts/darwin/<arch>/<name>)
  ren.kinds.mac = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = s: usersOf s.mac;
  };

  # standalone home-manager (old hosts/home/<arch>/<name>)
  ren.kinds.home = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = s: usersOf s.home;
  };

  # nix-on-droid (old hosts/android/<arch>/<name>)
  ren.kinds.droid = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = s: usersOf s.droid;
  };
}
