{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nix-topology-self.nixos =
    {
      globals-defs,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      isWgParticipant =
        ifName:
        globals.wireguard ? ${ifName}
        && (
          builtins.elem config.node.name globals.wireguard.${ifName}.clients
          || globals.wireguard.${ifName}.server == config.node.name
        );
    in
    {
      topology.self = {
        icon = lib.mkIf config.swarselsystems.isCloud "devices.cloud-server";
        interfaces = {
          lan = lib.mkIf (
            config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "lan"
          ) { };
          wan = lib.mkIf (
            config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "wan"
          ) { };
          wgHome = lib.mkIf (isWgParticipant "wgHome") {
            addresses = [
              globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts.${config.node.name}.ipv4
            ];
            renderer.hidePhysicalConnections = true;
            type = "wireguard";
            virtual = true;
          };
          wgProxy = lib.mkIf (isWgParticipant "wgProxy") {
            addresses = [
              globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts.${config.node.name}.ipv4
            ];
            renderer.hidePhysicalConnections = true;
            type = "wireguard";
            virtual = true;
          };
        };
      };
    }

  ;
}
