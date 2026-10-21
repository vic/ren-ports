# Interface classification: bridges, bonds, standalone NICs.
{ lib, host }:
let
  inherit (lib)
    attrNames
    concatMap
    imap0
    length
    listToAttrs
    mapAttrsToList
    subtractLists
    unique
    ;

  netCfg = host.networking;

  noAddrs = {
    ipv4 = [ ];
    ipv6 = [ ];
    mac = null;
  };

  allInterfaceNames = attrNames netCfg.interfaces;

  effectiveBridges =
    if netCfg.autobridging && netCfg.bridges == { } then
      listToAttrs (
        imap0 (idx: ifName: {
          name = "br${toString idx}";
          value = [ ifName ];
        }) allInterfaceNames
      )
    else
      netCfg.bridges;

  bridgeConfig = map (brName: {
    name = brName;
    interfaces = effectiveBridges.${brName};
    ifCfg =
      if length effectiveBridges.${brName} > 0 then
        netCfg.interfaces.${builtins.head effectiveBridges.${brName}} or noAddrs
      else
        noAddrs;
  }) (attrNames effectiveBridges);

  bondConfig = mapAttrsToList (bondName: bondCfg: {
    name = bondName;
    inherit (bondCfg) interfaces mode transmitHashPolicy;
    ifCfg = netCfg.interfaces.${bondName} or noAddrs;
  }) (netCfg.bonds or { });

  bridgeNames = map (br: br.name) bridgeConfig;
  bondNames = map (b: b.name) bondConfig;
  bridgedInterfaces = unique (concatMap (br: br.interfaces) bridgeConfig);
  bondedInterfaces = unique (concatMap (b: b.interfaces) bondConfig);
in
{
  inherit bridgeConfig bondConfig bridgeNames bondNames;

  # Standalone: not bridged, not bonded, not a virtual device name
  standaloneInterfaces = subtractLists (
    bridgedInterfaces ++ bondedInterfaces ++ bridgeNames ++ bondNames
  ) allInterfaceNames;

  allInterfaces = unique (allInterfaceNames ++ bridgedInterfaces ++ bridgeNames ++ bondNames);
}
