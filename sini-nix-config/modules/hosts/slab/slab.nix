{ ren, ... }:
{
  ren.droid.slab = {
    system = ren.system.aarch64-linux;
    channel = ren.channel.nixos-unstable;
    environment = ren.environment.dev;
    system-owner = ren.user.sini;
    users = [ ren.user.sini ];
  };

  # A droid host does NOT pull roles.default (the NixOS host baseline — boot,
  # systemd, networking, impermanence, agenix, openssh, …, none of which apply
  # to a Termux env). Its system layer is core.nix-on-droid-base; its tooling is
  # the homeManager half of roles.dev (bridged into nix-on-droid's
  # home-manager.config). The few NixOS-shaped emissions that den applies to
  # every host globally (define-user/hostname/user-to-host, system agenix) are
  # excluded/gated for droid hosts in batteries/nix-on-droid.nix and agenix.nix —
  # so nothing needs excluding here. roles.dev's nixos/os emissions (e.g.
  # hardware.adb) are simply not extracted for the droid class.
  ren.aspects.slab = {
    at = ren.droid.slab;
    includes = with ren.aspects; [
      dev
      app-shell-zsh
      nix-on-droid-base-droid
    ];
  };
}
