# ai-voxtype: push-to-talk speech-to-text daemon
{ ren, ... }:
{
  ren.aspects.ai-voxtype.homeManager = {
    # https://voxtype.io/: push-to-talk speech-to-text daemon, types the transcript into the focused window.
    services.voxtype = {
      enable = true;
      # Also puts wtype/wl-clipboard on the service's PATH, which typing into a Plasma Wayland session needs.
      wayland.display = "wayland-0";
      settings.whisper = {
        model = "base.en";
        language = "en";
      };
      loadModels = [ "base.en" ];
    };
  };
}
