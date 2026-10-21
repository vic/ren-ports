{ ren, lib, ... }:
{
  ren.mac.patch = {
    system = ren.system.aarch64-darwin;
    channel = ren.channel.nixpkgs-master;
    environment = ren.environment.dev;
    system-access-groups = [ ren.group.system-access ];
    system-owner = ren.user.sini;
    users = [ ren.user.sini ];
  };

  ren.aspects.patch = {
    at = ren.mac.patch;
    includes = with ren.aspects; [
      default
      dev
      darwin-workstation

      # Build Linux closures locally for the fleet. linux-builder (aarch64-linux,
      # cached image) bootstraps the toolchain; rosetta-builder (x86_64-linux +
      # aarch64-linux) can't be built until a Linux builder is already running,
      # so it's enabled in a second switch once this one is live:
      #   1. switch with linux-builder (below) -> aarch64-linux builder comes up
      #   2. swap to core.nix.rosetta-builder -> its image builds on that builder
      nix-linux-builder
    ];

    darwin = {
      # macOS uses uid 501 instead of 1000
      users.users.sini.uid = lib.mkForce 501;

      security.pam.services.sudo_local.touchIdAuth = true;

      # stateVersion is set by the core.nix.stateVersion aspect (darwin = 6).
      system.primaryUser = "sini";
    };
  };
}
