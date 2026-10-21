# audio-pipewire: pipewire + wireplumber + rtkit
{ ren, ... }:
{
  # pipewire + wireplumber + rtkit is a handful of always-on user services and an alsa/pulse compatibility layer.
  # A headless system with no sound card and no seat has no use for it.
  ren.aspects.audio-pipewire.nixos = {
    # The two are mutually exclusive; pipewire's pulse server takes the socket.
    services.pulseaudio.enable = false;

    # Lets pipewire ask for realtime scheduling without being setuid.
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
}
