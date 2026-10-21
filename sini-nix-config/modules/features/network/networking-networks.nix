# systemd.network.networks for network-networking: enslaved ports, bridge/bond
# devices, standalone NICs. Later attrs win on a name clash, as in den.
{ ... }:
{
  ren.aspects.network-networking.nixos =
    {
      environment,
      host,
      lib,
      ...
    }:
    let
      topo = import ./_networkd-topology.nix { inherit lib host; };
      mkNetworkConfig = import ./_networkd-config.nix { inherit lib environment; };
      enslaved =
        match: key: dev: ifName:
        lib.nameValuePair ifName {
          enable = true;
          matchConfig.Name = match ifName;
          networkConfig.${key} = dev;
          linkConfig.RequiredForOnline = "enslaved";
        };
      named =
        name: ifCfg:
        lib.nameValuePair name (
          {
            enable = true;
            matchConfig.Name = name;
          }
          // mkNetworkConfig ifCfg
        );
      brMatch = br: ifName: if br.name == "br0" then [ ifName "vm-*" ] else ifName;
    in
    {
      systemd.network.networks =
        lib.listToAttrs (
          lib.concatMap (br: map (enslaved (brMatch br) "Bridge" br.name) br.interfaces) topo.bridgeConfig
        )
        // lib.listToAttrs (
          lib.concatMap (b: map (enslaved lib.id "Bond" b.name) b.interfaces) topo.bondConfig
        )
        // lib.listToAttrs (
          map (n: named n host.networking.interfaces.${n}) topo.standaloneInterfaces
        )
        // lib.listToAttrs (map (br: named br.name br.ifCfg) topo.bridgeConfig)
        // lib.listToAttrs (map (b: named b.name b.ifCfg) topo.bondConfig);
    };
}
