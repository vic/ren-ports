# Prod environment instance: UniFi gateway (two WAN ports; only wan connected today).
{ ... }:
{
  ren.environment.prod.unifi = {
    wans = [
      "wan"
      "wan2"
    ];
    # Controller network names for nat port forwards: first WAN, and the LANs
    # whose clients reach them by the public address.
    networks = {
      wan = "Internet 1";
      lans = [
        "Default"
        "dev"
      ];
    };
    bgp = {
      description = "edge-prod";
      uploadFileName = "unifi-frr-bgp-prod.conf";
    };
  };
}
