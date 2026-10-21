# profiles (servers): local servers, MicroVM guests, the router
{ ren, ... }:
{
  ren.aspects.profile-localserver.includes = [
    # common modules
    ren.aspects.settings
    ren.aspects.lanzaboote
    ren.aspects.pii
    ren.aspects.xserver
    ren.aspects.time
    ren.aspects.users
    ren.aspects.impermanence
    ren.aspects.sops
    ren.aspects.boot
    # server modules
    ren.aspects.btrfs
    ren.aspects.nftables-rules
    ren.aspects.server-settings
    ren.aspects.disk-encrypt
    ren.aspects.ssh
    ren.aspects.server-network
    ren.aspects.server-packages
    ren.aspects.attic-setup
    ren.aspects.dns-hostrecord
    # ren.aspects.oauth2-proxy
    ren.aspects.node-roles
    ren.aspects.alloy
    ren.aspects.blackbox
  ];
  ren.aspects.profile-microvm = {
    includes = [
      # common modules
      ren.aspects.settings
      ren.aspects.pii
      ren.aspects.xserver
      ren.aspects.time
      ren.aspects.users
      ren.aspects.impermanence
      ren.aspects.sops
      # server modules
      ren.aspects.btrfs
      ren.aspects.nftables-rules
      ren.aspects.server-settings
      ren.aspects.ssh
      ren.aspects.server-packages
      ren.aspects.wireguard
      ren.aspects.dns-home
      ren.aspects.opkssh-server
      # ren.aspects.oauth2-proxy
      ren.aspects.node-roles
      ren.aspects.alloy
      ren.aspects.blackbox
    ];
    nixos.config.swarselsystems.isLinux = true;
  };
  ren.aspects.profile-router.includes = [
    ren.aspects.nftables-rules
    ren.aspects.router
    ren.aspects.kea
  ];
}
