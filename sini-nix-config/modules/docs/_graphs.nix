# Ren relationship sections of the README (fn of ren and lib): markdown + mermaid rendered from live Ren data
# (ren.kinds, ren.classes, ren.channels, ren.<kind> instances, ren.aspects). Pattern: vix modules/docs/_fleet-ir.nix + _readme-map.nix.
{ ren, lib }:
let
  inherit (builtins)
    attrNames
    attrValues
    concatStringsSep
    isAttrs
    length
    ;
  id = lib.replaceStrings [ "-" "." "@" " " "/" ] [ "_" "_" "_" "_" "_" ];
  q = l: ''"${l}"'';
  lines = concatStringsSep "\n";
  fence = body: lines ([ "```mermaid" ] ++ body ++ [ "```" ]);
  code = n: "`${n}`";
  table =
    head: rows:
    lines (
      map (r: "| ${concatStringsSep " | " r} |") ([
        head
        (map (_: "---") head)
      ] ++ rows)
    );
  names = xs: concatStringsSep ", " (map (x: x.name) xs);
  list = xs: if xs == [ ] then "" else concatStringsSep ", " xs;

  # a kind record names itself; anything else (predicate, helper fn, unset) is not a kind
  kn = x: if isAttrs x && (x.__ren or null) == "kind" then x.name else null;
  at = x: kn (x.at or null);
  into = x: kn (x.to or null);
  chans = attrNames ren.channels;
  classes = attrNames ren.classes;
  kinds = attrNames ren.kinds;
  inst = k: attrValues (ren.${k} or { });

  hosts = inst "host";
  macs = inst "mac";
  droids = inst "droid";
  guests = inst "guest";
  clusters = inst "cluster";
  envs = inst "environment";
  machines = hosts ++ macs ++ droids ++ guests;
  usersOfMachine = m: if m ? users then map (u: u.name) m.users else attrNames (ren.helpers.usersOf m);
  inEnv = e: lib.filter (m: m.environment.name == e.name) machines;
  uniqSort = xs: lib.sort (a: b: a < b) (lib.unique xs);
  allUsers = uniqSort (lib.concatMap usersOfMachine (hosts ++ macs));

  # group channels or classes by (emitter kind, receiver kind): one edge per pair
  pairs =
    from: to: ns:
    lib.mapAttrsToList (k: v: v) (
      lib.foldl' (
        acc: n:
        let
          f = from n;
          t = to n;
          k = "${f}>${t}";
        in
        acc // { ${k} = { inherit f t; ns = (acc.${k}.ns or [ ]) ++ [ n ]; }; }
      ) { } ns
    );
  chanPairs = pairs (c: or' (at ren.channels.${c}) "any") (c: or' (into ren.channels.${c}) "computed") chans;
  or' = v: d: if v == null then d else v;
  classAt = c: or' (at ren.classes.${c}) "any";
  node = n: ''  ${id "n-${n}"}[${q n}]'';
  edge = f: t: l: ''  ${id "n-${f}"} -->${if l == "" then "" else "|${q l}|"} ${id "n-${t}"}'';
  nodesOf = es: lib.unique (lib.concatMap (e: [ e.f e.t ]) es);
in
{
  # Fleet Topology + Scope Topology: kind tree (below) and `is` inheritance, then instances per environment.
  scopeTopology = lines [
    "# Fleet Topology"
    ""
    "Generated from live Ren data (`ren.kinds`, `ren.<kind>`, `ren.classes`, `ren.channels`): the kind tree, how classes forward modules and how channels move data."
    ""
    "## Scope Topology"
    ""
    "Kind tree: solid edges are `below` (parent scope to child scope), dotted edges are `is` (inheritance)."
    ""
    (fence (
      [ "flowchart TD" ]
      ++ map (k: node k) kinds
      ++ lib.concatMap (k: map (b: edge k b "") ren.kinds.${k}.below) kinds
      ++ lib.concatMap (k: lib.optional (ren.kinds.${k}.is != null) "  ${id "n-${k}"} -.->|\"is\"| ${id "n-${ren.kinds.${k}.is}"}") kinds
    ))
    ""
    "Instances: fleet, environments, machines (`[host]` `(mac)` `[/droid/]` `[[guest]]`), clusters and domains."
    ""
    (fence (
      [ "flowchart LR" ]
      ++ map (f: "  ${id "fleet-${f.name}"}[${q "fleet: ${f.name}"}]") (inst "fleet")
      ++ lib.concatMap (e: [
        "  ${id "env-${e.name}"}[${q "env: ${e.name}"}]"
        "  ${id "fleet-sini"} --> ${id "env-${e.name}"}"
      ]) envs
      ++ map (m: "  ${id "host-${m.name}"}[${q m.name}]") hosts
      ++ map (m: "  ${id "host-${m.name}"}(${q m.name})") macs
      ++ map (m: "  ${id "host-${m.name}"}[/${q m.name}/]") droids
      ++ map (m: "  ${id "host-${m.name}"}[[${q m.name}]]") guests
      ++ map (m: "  ${id "env-${m.environment.name}"} --> ${id "host-${m.name}"}") (hosts ++ macs ++ droids)
      ++ lib.concatMap (h: map (g: "  ${id "host-${h.name}"} -->|\"guest\"| ${id "host-${g.name}"}") h.guests) hosts
      ++ lib.concatMap (c: [
        "  ${id "cluster-${c.name}"}[(${q "cluster: ${c.name}"})]"
        "  ${id "env-${c.environment.name}"} --> ${id "cluster-${c.name}"}"
      ] ++ map (h: "  ${id "cluster-${c.name}"} -.-> ${id "host-${h.name}"}") c.hosts) clusters
      ++ map (d: "  ${id "domain-${d.name}"}([${q d.name}])") (inst "domain")
      ++ map (d: "  ${id "fleet-sini"} --> ${id "domain-${d.name}"}") (inst "domain")
    ))
    ""
  ];

  # Policy Resolution: class forwarding (aspect key -> class -> `at` kind).
  policyResolution = lines [
    "## Policy Resolution"
    ""
    "Class resolution: an aspect key naming a class sends its modules to the class, which collects them at its `at` kind."
    ""
    (fence (
      [ "flowchart LR" ]
      ++ map (c: ''  ${id "class-${c}"}(${q c})'') classes
      ++ map (k: node k) (lib.unique (map classAt classes))
      ++ map (c: "  ${id "class-${c}"} --> ${id "n-${classAt c}"}") classes
    ))
    ""
  ];

  # Pipe Flow: channels grouped by (emitter kind -> receiver kind).
  pipeFlow = lines [
    "## Pipe Flow"
    ""
    "Channels: aspects emit at the `at` kind; the receiver `to` folds the pool. One edge per kind pair, labelled with its channels."
    ""
    (fence (
      [ "flowchart LR" ]
      ++ map node (nodesOf chanPairs)
      ++ map (p: edge p.f p.t "${toString (length p.ns)}: ${list p.ns}") chanPairs
    ))
    ""
  ];

  # Pipe Sequence: sequence diagram of the same pairs.
  pipeSequence = lines [
    "## Pipe Sequence"
    ""
    "Order of emission by kind pair (channel names are Ren-global; each edge lists its channels)."
    ""
    (fence (
      [ "sequenceDiagram" ]
      ++ map (n: "  participant ${id n} as ${n}") (nodesOf chanPairs)
      ++ map (p: "  ${id p.f}->>${id p.t}: ${list p.ns}") chanPairs
    ))
    ""
  ];

  summaryTopology = lines [
    "## Fleet Summary"
    ""
    "# Fleet Summary"
    ""
    "## Topology"
    ""
    "- **${toString (length envs)}** environments, **${toString (length machines)}** machines (${toString (length hosts)} hosts, ${toString (length macs)} macs, ${toString (length droids)} droids, ${toString (length guests)} guests), **${toString (length allUsers)}** users, **${toString (length clusters)}** clusters, **${toString (length (inst "domain"))}** domains"
    "- Scope chain: fleet, then environment | domain | system, then machine, then user | guest"
    "- Kinds: **${toString (length kinds)}**, classes: **${toString (length classes)}**, channels: **${toString (length chans)}**, aspects: **${toString (length (attrNames ren.aspects))}**"
    ""
    (table [ "Kind" "Below" "Is" "Instances" ] (map (k: [
      (code k)
      (list ren.kinds.${k}.below)
      (or' ren.kinds.${k}.is "")
      (toString (length (attrNames (ren.${k} or { }))))
    ]) kinds))
    ""
  ];

  summaryEnvironments = lines [
    "## Environments"
    ""
    (table [ "Environment" "Hosts" "Host Count" "Users" ] (map (e: [
      e.name
      (names (inEnv e))
      (toString (length (inEnv e)))
      (toString (length (uniqSort (lib.concatMap usersOfMachine (lib.filter (m: lib.elem m (hosts ++ macs)) (inEnv e))))))
    ]) envs))
    ""
  ];

  summaryAspects = lines [
    "## Aspects by Host"
    ""
    (table [ "Host" "Aspect Count" "Aspects" ] (map (m:
      let inc = map (a: a.name or "?") ((ren.aspects.${m.name} or { }).includes or [ ]);
      in [ m.name (toString (length inc)) (list inc) ]) machines))
    ""
  ];

  summaryPipes = lines [
    "## Pipes"
    ""
    (table [ "Pipe" "Emitted at" "Received by" ] (map (c: [
      (code c)
      (or' (at ren.channels.${c}) "any")
      (or' (into ren.channels.${c}) "computed")
    ]) chans))
    ""
  ];

  summaryPolicies = lines [
    "## Policies"
    ""
    (table [ "Policy (class)" "Fires at" ] (map (c: [ (code c) (classAt c) ]) classes))
    ""
  ];
}
