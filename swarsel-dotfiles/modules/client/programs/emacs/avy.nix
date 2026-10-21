{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.avy = {
    enable = true;
    bind.M-o = "avy-goto-char-timer";
    custom.avy-all-windows = "'all-frames";
  };
}
