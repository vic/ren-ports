# Machine networking: interfaces, bonds and bridges (den host.networking).
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  ifaceT = t.submodule {
    options.ipv4 = opt (t.listOf t.str) [ ];
    options.ipv6 = opt (t.listOf t.str) [ ];
    options.dhcp = opt (t.nullOr (t.enum [ "none" "ipv4" "ipv6" "yes" ])) null;
    options.managed = opt t.bool true;
    options.mtu = maybe t.int;
    options.mac = maybe t.str;
    options.linkLocal = maybe t.str;
    options.requiredForOnline = maybe t.str;
    options.privacyExtensions = maybe t.str;
    options.acceptRAAutonomousPrefix = maybe t.bool;
  };
  bondT = t.submodule {
    options.interfaces = opt (t.listOf t.str) [ ];
    options.mode = opt t.str "balance-rr";
    options.transmitHashPolicy = maybe t.str;
  };
in
{
  ren.kinds.machine.networking = {
    interfaces = opt (t.attrsOf ifaceT) { };
    bonds = opt (t.attrsOf bondT) { };
    autobridging = opt t.bool false;
    bridges = opt (t.attrsOf (t.listOf t.str)) { };
  };
}
