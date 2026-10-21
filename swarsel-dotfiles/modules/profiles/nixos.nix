# profiles (NixOS): what each kind of NixOS machine includes; the homeManager halves are in home.nix
{ ren, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  # old mkNixosHost: `++ lib.optionals minimal [ profile-minimal ]`
  ren.aspects.profile-minimal = {
    at = and [
      sw.metal
      (within ren.variant.minimal)
    ];
    includes = [
      ren.aspects.settings
      ren.aspects.home-manager
      ren.aspects.xserver
      ren.aspects.lanzaboote
      ren.aspects.time
      ren.aspects.users
      ren.aspects.impermanence
      ren.aspects.sops
      ren.aspects.boot
      ren.aspects.autologin
      ren.aspects.btrfs
      ren.aspects.ssh
      ren.aspects.disk-encrypt
      ren.aspects.pii
    ];
  };
  ren.aspects.profile-personal.includes = [
      ren.aspects.profile-public
      ren.aspects.hardwarecompatibility-yubikey
      ren.aspects.sandbox-access
      ren.aspects.ssh
  ];
  ren.aspects.profile-public.includes = [
      ren.aspects.profile-public-small
      ren.aspects.appimage
      ren.aspects.distrobox
      ren.aspects.hardwarecompatibility-keyboards
      ren.aspects.hardwarecompatibility-ledger
      ren.aspects.lid
      ren.aspects.networkdevices
      ren.aspects.nix-ld
  ];
  ren.aspects.profile-public-small.includes = [
      ren.aspects.settings
      ren.aspects.lanzaboote
      ren.aspects.home-manager
      ren.aspects.xserver
      ren.aspects.time
      ren.aspects.users
      ren.aspects.impermanence
      ren.aspects.sops
      ren.aspects.boot
      ren.aspects.autologin
      ren.aspects.blueman
      ren.aspects.env
      ren.aspects.firezone-client
      ren.aspects.gnome-keyring
      ren.aspects.gvfs
      ren.aspects.hardware
      ren.aspects.interceptiontools
      ren.aspects.login
      ren.aspects.nautilus
      ren.aspects.network
      ren.aspects.nvd-rebuild
      ren.aspects.packages
      ren.aspects.pipewire
      ren.aspects.polkit
      ren.aspects.power-profiles-daemon
      ren.aspects.programs
      ren.aspects.pulseaudio
      ren.aspects.remotebuild
      ren.aspects.stylix
      ren.aspects.syncthing
      ren.aspects.systemd
      ren.aspects.uwsm
      ren.aspects.xdg-portal
      ren.aspects.zsh-system
      ren.aspects.btrfs
      ren.aspects.nftables-rules
      ren.aspects.pii
  ];
}
