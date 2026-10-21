{ ... }:
{
  ren.aspects.app-media-easyeffects = {
    nixos = {
      programs.noisetorch.enable = true;
    };

    homeManager = {
      services.easyeffects.enable = true;

      xdg.dataFile = {
        "easyeffects/input/improved-microphone.json".source = ./_easyeffects/presets/ImprovedMicrophone.json;
        "easyeffects/output/HD650-Harmon.json".source = ./_easyeffects/presets/HD650-Harmon.json;
        "easyeffects/output/HD6XX.json".source = ./_easyeffects/presets/HD6XX.json;
        "easyeffects/output/GalaxyBuds.json".source = ./_easyeffects/presets/GalaxyBuds.json;
      };
    };

    persistHome.directories = [
      ".local/share/easyeffects"
    ];
  };
}
