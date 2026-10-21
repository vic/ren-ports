# Names shared by the genie-xmsg*.nix files (den: let-bindings of genie-xmsg.nix).
rec {
  tiers = [
    "public"
    "trusted"
  ];
  user = tier: "genie-${tier}";
  homeOf = tier: "/var/lib/${user tier}";
  runtimeDir = tier: "/run/xmsg-${tier}";
  stateDir = tier: "/var/lib/xmsg-${tier}";
  keyName = tier: "xmsg-${user tier}";
}
