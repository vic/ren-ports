# Bridge and bond netdevs/links for network-networking.
{ ... }:
{
  ren.aspects.network-networking.nixos =
    { host, lib, ... }:
    let
      topo = import ./_networkd-topology.nix { inherit lib host; };
    in
    {
      systemd.network.netdevs =
        lib.listToAttrs (
          map (
            br:
            lib.nameValuePair br.name {
              # A bridge does NOT inherit a port's MAC (measured). `MACAddress = "none"`
              # means KERNEL-RANDOM, fresh every boot, which flips the host's L2
              # identity (router sees a new device, peers hold stale ARP). Pin it to
              # the enslaved NIC's MAC; with none declared, networkd's machine-id
              # derived address is at least stable.
              netdevConfig = {
                Name = br.name;
                Kind = "bridge";
              }
              // lib.optionalAttrs (br.ifCfg.mac or null != null) { MACAddress = br.ifCfg.mac; };
            }
          ) topo.bridgeConfig
        )
        // lib.listToAttrs (
          map (
            bond:
            lib.nameValuePair bond.name {
              netdevConfig = {
                Name = bond.name;
                Kind = "bond";
              };
              bondConfig = {
                Mode = bond.mode;
              }
              // lib.optionalAttrs (bond.transmitHashPolicy != null) {
                TransmitHashPolicy = bond.transmitHashPolicy;
              };
            }
          ) topo.bondConfig
        );

      systemd.network.links = lib.listToAttrs (
        map (
          br:
          lib.nameValuePair br.name {
            matchConfig.Name = br.name;
            linkConfig.MACAddressPolicy = "none";
          }
        ) topo.bridgeConfig
      );
    };
}
