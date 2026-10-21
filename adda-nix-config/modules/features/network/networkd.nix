# networkd + nftables on every host (NetworkManager, where enabled, manages the interfaces).
{ ren, ... }:
{
  ren.aspects.networkd = {
    at = ren.kinds.host;
    nixos = {
      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      networking = {
        useNetworkd = true;
        enableIPv6 = true;
        nftables.enable = true;
      };

      # NetworkManager (not networkd) actually manages the interfaces here, so from networkd's point of view they're all
      #  "unmanaged" and systemd-networkd-wait-online has nothing to wait on: it always times out (even with anyInterface)
      #  despite NetworkManager-wait-online already satisfying network-online.target. Disable it entirely.
      systemd.network.wait-online.enable = false;
    };
  };
}
