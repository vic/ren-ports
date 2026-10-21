# addressOn env net host -> host's IPv4 (prefix stripped) inside env.networks.<net>.cidr
# (den schema/environment.nix addressOn). Throws when the host has none.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  ipToInt = ip: lib.foldl' (acc: o: acc * 256 + lib.toInt o) 0 (lib.splitString "." ip);
  cidrOf = env: net: lib.splitString "/" env.networks.${net}.cidr;
  blockSize = cidr: lib.foldl' (acc: _: acc * 2) 1 (lib.range 1 (32 - lib.toInt (lib.last cidr)));
  inNet = cidr: ip: ipToInt ip / blockSize cidr == ipToInt (lib.head cidr) / blockSize cidr;
  addrsOf =
    host:
    lib.concatMap (i: map (a: lib.head (lib.splitString "/" a)) i.ipv4) (
      lib.attrValues host.networking.interfaces
    );
in
{
  ren.helpers.addressOn =
    env: net: host:
    lib.findFirst (inNet (cidrOf env net)) (throw "ren: host '${host.name}' has no IPv4 in ${env.name}.networks.${net} (${
      env.networks.${net}.cidr
    })") (addrsOf host);
}
