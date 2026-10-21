# Shared pure fns of the unifi workspace (sini flake-parts/terranix/unifi.nix).
{ lib }:
rec {
  # ponytail: one environment owns the gateway; key configs by env if a second controller appears.
  unifiEnv = "prod";
  workdir = "infra/unifi";

  # A controller name as a resource name: lowercased, each run of other
  # characters as `_`, the key unifi-adopt derives (portForwardImports).
  key =
    n:
    let
      k = lib.removePrefix "_" (
        lib.removeSuffix "_" (
          lib.concatMapStrings (x: if builtins.isList x then "_" else x) (
            builtins.split "[^a-z0-9]+" (lib.toLower n)
          )
        )
      );
    in
    if builtins.match "[0-9].*" k != null then "pf_" + k else k;

  # `env`'s port-forwards records of one mode ("forward" when unset), keyed by
  # resource name. Two of any mode with the same key, or overlapping WAN ports
  # on overlapping protocols, are refused.
  # ponytail: overlap compares single ports and comma lists, not "a-b" ranges.
  recordsOf =
    mode: env: forwards:
    let
      modeOf =
        r:
        let
          m = r.mode or "forward";
        in
        if
          builtins.elem m [
            "forward"
            "nat"
          ]
        then
          m
        else
          throw "unifi: port forward ${r.name} has mode ${m}, not forward or nat";
      own = builtins.filter (r: r.environment == env) forwards;
      ports = r: lib.splitString "," r.wanPort;
      overlaps =
        a: b:
        (a.protocol == b.protocol || a.protocol == "tcp_udp" || b.protocol == "tcp_udp")
        && lib.intersectLists (ports a) (ports b) != [ ];
      check =
        i: r:
        let
          earlier = lib.take i own;
          clash = lib.findFirst (o: key o.name == key r.name) null earlier;
          portClash = lib.findFirst (o: overlaps o r) null earlier;
        in
        if clash != null then
          throw "unifi: port forwards ${clash.name} and ${r.name} share the resource name ${key r.name}"
        else if portClash != null then
          throw "unifi: port forwards ${portClash.name} and ${r.name} both take ${r.protocol} wan:${r.wanPort}"
        else
          lib.nameValuePair (key r.name) r;
    in
    builtins.filter ({ value, ... }: modeOf value == mode) (lib.imap0 check own);
}
