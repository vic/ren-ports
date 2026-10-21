{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.appimage.nixos.config.programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
