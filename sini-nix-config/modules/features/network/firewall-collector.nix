# The `firewall` channel (channels/edge-am.nix) merges the rules in its `into`; this aspect carries no config.
{ ... }:
{
  ren.aspects.network-firewall-collector = { };
}
