# summers-audio: old hosts/nixos/x86_64-linux/summers/guests/audio/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-audio = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-audio.at = ren.guest.summers-audio;
  ren.aspects.summers-audio.includes = [
    ren.aspects.mpd
    ren.aspects.navidrome
    ren.aspects.profile-microvm
    ren.aspects.spotifyd
  ];
  ren.aspects.summers-audio.nixos =
    {
      variant,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
      ];

      swarselsystems = {
        isMicroVM = true;
      };

    }
    // lib.optionalAttrs (!variant.minimal) {

      environment.persistence."/state".directories = [
        {
          directory = "/var/lib/alsa";
          group = "root";
          user = "root";
        }
      ];
      microvm = {
        devices = [
          {
            bus = "pci";
            path = "0000:04:04.0";
          }
        ];
        mem = 1024 * 4;
        qemu.machine = "q35";
        vcpu = 2;
      };
      systemd.services.audio-mixer-init = {
        after = [ "sound.target" ];
        script = ''
          ${pkgs.alsa-utils}/bin/amixer -c 0 sset 'Analog Output' Multichannel
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        wantedBy = [ "sound.target" ];
      };

    };
}
