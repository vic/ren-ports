{ ren, lib, ... }:
{
  ren.aspects.default = {
    includes = with ren.aspects; [
      nix
      nix-nixpkgs
      systemd-boot
      localization-i18n
      nix-stateVersion
      systemd
      users-shell
      utils
      system-firmware
      security
      system-facter
      users-home-manager-shared
      users-deterministic-uids
      security-sudo
      localization-time
      perf-disable-docs
      perf-ssd
      perf-zram-swap
      system-linux-kernel
      users
      users-root-user
      impermanence
      app-shell-zsh
      network-networking
      security-openssh
      security-opkssh
      network-hostsfile
      network-tailscale
      network-syncthing-member-homeManager
      secrets-agenix
      # den.schema.host.includes (den/defaults.nix) folded in:
      network-firewall-collector
      secrets-collector
      # den.schema.user.includes (defaults.nix, syncthing/peers.nix, mcp/xmsg.nix) folded in:
      users-resolved-user-emitter
      network-syncthing-peer
      dev-ai-mcp-xmsg-node-xmsg-nodes
      default-hostname
      default-define-user
      default-primary-user
    ];
  };

  # den.batteries.hostname: the machine name is the host name.
  ren.aspects.default-hostname.nixos = { host, ... }: { networking.hostName = host.name; };

  # den.batteries.define-user: a login account per user on the host.
  ren.aspects.default-define-user = {
    at = ren.lib.and [ ren.kinds.user (ren.lib.within ren.kinds.host) ];
    account.isNormalUser = true;
  };

  # den policy primary-user-for-owner: den.batteries.primary-user (wheel, networkmanager) for the host's
  # system-owner only, not for every login user.
  ren.aspects.default-primary-user = {
    at = ren.lib.and [
      ren.kinds.user
      (ren.lib.within ren.kinds.host)
      (ren.lib.when ({ host, user, ... }: host.system-owner != null && ren.lib.same user host.system-owner))
    ];
    account =
      { is, host, ... }:
      {
        extraGroups = [ "wheel" ] ++ lib.optional (is ren.aspects.network-manager host) "networkmanager";
      };
  };

  # den policy user-aspect-auto-include (den.aspects.<host>.<user>): a host+user pair aspect is `at` a user
  # within that host (README.md:559). inputs'/self' batteries are per-system indexing (system.name).
}
