# pi: Stylix-derived theme (falls back to catppuccin-mocha colours without stylix).
{ ... }:
{
  ren.aspects.dev-ai-agents-pi.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Check if stylix colors are available
      hasStylix = config ? lib.stylix && config.lib.stylix ? colors;
      s =
        if hasStylix then
          config.lib.stylix.colors.withHashtag
        else
          {
            base00 = "#1e1e2e";
            base01 = "#181825";
            base02 = "#313244";
            base03 = "#45475a";
            base04 = "#585b70";
            base05 = "#cdd6f4";
            base08 = "#f38ba8";
            base09 = "#fab387";
            base0A = "#f9e2af";
            base0B = "#a6e3a1";
            base0C = "#94e2d5";
            base0D = "#89b4fa";
            base0E = "#cba6f7";
          };

      stylixTheme = pkgs.writeText "stylix.json" (
        builtins.toJSON {
          "$schema" =
            "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
          name = "stylix";
          vars = {
            bg = s.base00;
            bgLight = s.base01;
            selection = s.base02;
            comment = s.base03;
            fgDark = s.base04;
            fg = s.base05;
            red = s.base08;
            orange = s.base09;
            yellow = s.base0A;
            green = s.base0B;
            cyan = s.base0C;
            blue = s.base0D;
            magenta = s.base0E;
          };
          colors = import ./_pi/theme-colors.nix;
        }
      );
    in
    {
      # Deploy Stylix theme for pi
      home.file.".pi/agent/themes/stylix.json".source = stylixTheme;
    };
}
