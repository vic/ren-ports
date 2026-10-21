{ ... }:
{
  ren.aspects.hardware-audio = {
    nixos =
      { lib, ... }:
      {
        security.rtkit.enable = true;
        services.pulseaudio.enable = lib.mkForce false;
        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          wireplumber.enable = true;
          jack.enable = true;
          pulse.enable = true;

          wireplumber.extraConfig = {
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.roles" = [
                "hsp_hs"
                "hsp_ag"
                "hfp_hf"
                "hfp_ag"
              ];
            };
          };

          extraConfig = {
            client."10-resample" = {
              "stream.properties" = {
                "resample.quality" = 10;
              };
            };

            pipewire."99-playback-96khz" = {
              "context.properties" = {
                "default.clock.rate" = 48000;
                "default.clock.allowed-rates" = [
                  44100
                  48000
                  88200
                  96000
                  176400
                  192000
                ];
              };
            };
          };
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.wiremix
        ];
      };

    persistHome = {
      directories = [
        ".local/state/wireplumber"
        ".config/rncbc.org"
        ".config/pulse"
      ];
    };
  };
}
