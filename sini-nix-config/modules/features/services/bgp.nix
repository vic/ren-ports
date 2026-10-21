# BGP base aspect, FRR bgpd with configurable neighbors, prefix lists, route maps.
# Options: bgp/options.nix, bgp/options-groups.nix. FRR rendering: bgp/render-head.nix.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-bgp = ren.lib.opt (lib.types.submodule {
    options.localAsn = lib.mkOption {
      type = lib.types.int;
      default = 65001;
      description = "Local BGP AS number for this node";
    };
  }) { };

  ren.aspects.svc-bgp = {
    # Emit peer info for hub auto-discovery
    bgp-peers =
      { host, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        asn = host.svc-bgp.localAsn;
      };

    firewall = {
      networking.firewall.allowedTCPPorts = [ 179 ];
    };
  };
}
