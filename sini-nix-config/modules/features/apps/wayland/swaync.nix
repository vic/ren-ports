{ ... }:
{
  ren.aspects.app-wayland-swaync.homeManager =
    { config, lib, pkgs, ... }:
    let
      accent = "#${config.lib.stylix.colors.base0D}";
      background = "#${config.lib.stylix.colors.base00}";
      foreground = "#${config.lib.stylix.colors.base05}";
      borderSize = 5;
      nerdFont = config.stylix.fonts.sansSerif.name;
      theme = pkgs.writeTextFile {
        name = "swayosd-css";
        text = ''
          window#osd {
            padding: 12px 18px;
            border-radius: 999px;
            border: solid ${toString borderSize}px ${accent};
            background: alpha(${background}, 0.99);
          }

          #container {
            margin: 0px;
          }

          image {
            font-family: "${nerdFont}";
            font-size: 14px;
            color: ${foreground};
          }

          label {
            color: ${foreground};
          }

          progressbar:disabled,
          image:disabled {
            opacity: 0.5;
          }

          progressbar {
            min-width: 150px;
            min-height: 5px;
            border-radius: 999px;
            background: transparent;
            border: none;
          }

          trough {
            min-height: inherit;
            border-radius: inherit;
            border: none;
            background: alpha(${accent},0.3);
          }

          progress {
            min-height: inherit;
            border-radius: inherit;
            border: none;
            background: ${accent};
          }
        '';
      };
    in
    {
      systemd.user.services.swayosd = {
        Unit.ConditionEnvironment = lib.mkForce [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
        Service.Slice = "background-graphical.slice";
      };

      services.swayosd = {
        enable = true;
        stylePath = theme;
      };
    };
}
