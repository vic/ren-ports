# Names shared by the genie-expert*.nix files (den: let-bindings of genie-expert.nix).
rec {
  shared = "/var/lib/genie";
  publicClones = "${shared}/public-repos";
  secret = "genie-claude-token";
  tiers = [
    "public"
    "trusted"
  ];
  user = tier: "genie-${tier}";
  homeOf = tier: "/var/lib/${user tier}";
  ownerCheckouts = "${homeOf "trusted"}/repos";
}
