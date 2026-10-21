{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nautilus.nixos.config.programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
}
