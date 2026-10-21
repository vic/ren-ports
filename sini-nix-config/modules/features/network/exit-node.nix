# Tailnet exit node: advertises a default route through this host. Emits the
# exit-nodes channel so headscale auto-approves the route.
{ ... }:
{
  ren.aspects.network-tailscale-exit-node = {
    exit-nodes =
      { host, ... }:
      {
        hostname = host.name;
      };

    nixos.services.tailscale = {
      useRoutingFeatures = "server";
      # `tailscale set` runs on every start; up flags only apply at first login.
      extraSetFlags = [ "--advertise-exit-node" ];
    };
  };
}
