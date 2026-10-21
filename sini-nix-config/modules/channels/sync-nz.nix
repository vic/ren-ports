# channels n-z (mesh family, user|host peers): syncthing-peers, replicate-home, xmsg-*.
{ ren, lib, ... }:
let
  inherit (ren.lib) and anyOf when same;
  userOrHost = anyOf [ ren.kinds.user ren.kinds.host ];
  xl = import ../features/dev/ai/_xmsg-lib.nix { inherit lib; self = ../..; };
  # policies/xmsg.nix, as receivers of one emission `e` (`when` sees the receiver's bindings, README:289):
  #   same-user + trusted-pairs: a user node reaches the user nodes of trusted users (`trusts` includes the same user);
  #   service nodes (emitted at a host scope): reach the host's system owner's user scopes; the owner's user nodes
  #   are collected back at hosts that owner runs; clusters collect the service nodes of their hosts.
  xmsgTo =
    e:
    let
      fromUser = e ? user;
    in
    anyOf [
      (and [
        ren.kinds.user
        (when (
          { user, ... }:
          if fromUser then
            xl.trusts e.user.name user.name
          else
            e.host.system-owner != null && same e.host.system-owner user
        ))
      ])
      (and [
        ren.kinds.host
        (when ({ host, ... }: fromUser && host.system-owner != null && same host.system-owner e.user))
      ])
      (and [
        ren.kinds.cluster
        (when ({ cluster, ... }: !fromUser && lib.any (same e.host) cluster.hosts))
      ])
    ];
  peers = {
    fold = ren.lib.fold.list;
    at = userOrHost;
    to = _: userOrHost;
  };
in
{
  ren.channels.syncthing-peers = peers // { into = { ... }: p: { syncthing-peers = p; }; };
  ren.channels.replicateHome = peers // { into = { ... }: p: { replicateHome = p; }; };
  ren.channels.xmsg-nodes = peers // {
    to = xmsgTo;
    into = { ... }: n: { xmsg-nodes = n; };
  };
  # cluster -> host
  ren.channels.xmsg-leaves = {
    fold = ren.lib.fold.list;
    at = ren.kinds.cluster;
    to = _: ren.kinds.host;
    into = { ... }: l: { xmsg-leaves = l; };
  };
}
