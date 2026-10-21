{ ... }:
{
  ren.aspects.svc-k3s-base.nixos = {
    networking.nftables.enable = true;
    networking.firewall.filterForward = true;
  };
}
