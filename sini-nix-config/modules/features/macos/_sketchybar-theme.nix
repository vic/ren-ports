# sketchybar palette: stylix base16 -> 0xAARRGGBB
{ config }:
let
  # TODO: Abstract away stylix dependency
  inherit (config.lib.stylix) colors;
  # "rrggbb" (stylix) -> 0xAARRGGBB (sketchybar).
  argb = alpha: hex: "0x${alpha}${hex}";
in
{
  font = config.stylix.fonts.monospace.name;
  bg = argb "ff" colors.base00; # solid, for text on accent
  surface = argb "f2" colors.base01; # pill background (no bar blur, so near-opaque)
  fg = argb "ff" colors.base05;
  muted = argb "ff" colors.base04;
  accent = argb "ff" colors.base0D; # blue
  green = argb "ff" colors.base0B;
  red = argb "ff" colors.base08;
}
