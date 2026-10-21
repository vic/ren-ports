# fleet ir (a fn of ren and chans): nodes + edges of three views (scopes, channels, classes) from live Ren data; `_readme-map.nix` renders each.
{
  ren,
  chans,
}:
let
  inherit (builtins)
    attrNames
    attrValues
    concatMap
    elem
    filter
    match
    replaceStrings
    throw
    ;
  id = replaceStrings [ "-" "." "@" " " "/" ] [ "_" "_" "_" "_" "_" ];
  node = kind: label: group: {
    id = id "${kind}-${label}";
    inherit kind label group;
  };
  edge = from: to: label: { inherit from to label; };
  # one node per label (a label two edges share is drawn once), ordered by id
  uniq =
    ns:
    builtins.sort (a: b: a.id < b.id) (
      attrValues (
        builtins.listToAttrs (
          map (n: {
            name = n.id;
            value = n;
          }) ns
        )
      )
    );
  hosts = attrValues ren.host;
  fleets = attrValues ren.fleet;
  sys = i: id "system-${i.system.name}";
  used = filter (s: elem (sys { system = s; }) (map sys hosts)) (attrValues ren.system);
  # channels: guarded like the vocabulary tables, one line per live channel
  ends = c: match "(.*) -> (.*)" chans.${c};
  bad =
    filter (c: !(chans ? ${c})) (attrNames ren.channels)
    ++ filter (c: !(ren.channels ? ${c}) || ends c == null) (attrNames chans);
  pair =
    c:
    if bad == [ ] then
      ends c
    else
      throw "docs/_fleet-channels.nix: missing, stale or malformed [${toString bad}]";
  cs = attrNames chans;
in
{
  scopes = {
    nodes =
      map (f: node "fleet" f.name null) fleets
      ++ map (s: node "system" s.name null) used
      ++ map (h: node "host" h.name (sys h)) hosts
      ++ map (u: node "user" u.name null) (attrValues ren.user);
    # Ren roots: the fleet lists the systems; each host spawns a scope per user
    edges =
      concatMap (f: map (s: edge (id "fleet-${f.name}") (id "system-${s.name}") "") used) fleets
      ++ concatMap (h: map (u: edge (id "host-${h.name}") (id "user-${u.name}") "") h.users) hosts;
  };
  channels = {
    nodes = uniq (
      concatMap (c: [
        (node "emitter" (builtins.elemAt (pair c) 0) null)
        (node "receiver" (builtins.elemAt (pair c) 1) null)
      ]) cs
    );
    edges = map (
      c: edge (id "emitter-${builtins.elemAt (pair c) 0}") (id "receiver-${builtins.elemAt (pair c) 1}") c
    ) cs;
  };
  classes = import ./_fleet-classes.nix {
    inherit
      ren
      id
      uniq
      hosts
      ;
  };
}
