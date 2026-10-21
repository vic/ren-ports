# network: NetworkManager for machines that move
{ ren, ... }:
{
  # NetworkManager: roaming between wifi networks, VPN plugins, a tray applet, and ModemManager alongside it. All of that
  # is for a machine that moves.
  #
  # A host that leaves this out is not left without networking: modules/aspects/network sets `networking.useNetworkd = true`,
  # and with `networking.useDHCP = true` nixpkgs emits the catch-all `99-ethernet-default-dhcp` .network unit, which is
  # exactly what a server on a wired link wants.
  #
  # The `networkmanager` group that modules/users/adda adds to the primary user is  created by this module; it is simply
  # unused where the aspect is absent.
  ren.aspects.network-networkManager.nixos = {
    networking.networkmanager.enable = true;
  };
}
