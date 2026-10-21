# Base networkd/firewall setup. Bridge/bond netdevs and networks:
# networking-netdevs.nix, networking-networks.nix (same aspect).
{ ren, ... }:
{
  ren.aspects.network-networking.nixos =
    {
      environment,
      is,
      host,
      lib,
      ...
    }:
    let
      topo = import ./_networkd-topology.nix { inherit lib host; };
    in
    {
      boot.kernelModules = [
        "tun"
        "bridge"
        "macvtap"
        "bonding"
      ];

      networking = {
        hostName = host.name;
        domain = "${environment.name}.${environment.domain}";
        hostId = builtins.substring 0 8 (builtins.hashString "md5" host.name);

        useNetworkd = true;
        useDHCP = false;

        networkmanager.enable = lib.mkForce (is ren.aspects.network-manager host);
        networkmanager.unmanaged = topo.allInterfaces ++ topo.bridgeNames ++ topo.bondNames;

        dhcpcd.enable = false;

        firewall = {
          enable = true;
          allowPing = true;
          logRefusedConnections = false;
        };
      };

      systemd.services."systemd-networkd-persistent-storage".enable = false;

      systemd.network = {
        enable = true;
        wait-online.enable = false;
      };
    };
}
