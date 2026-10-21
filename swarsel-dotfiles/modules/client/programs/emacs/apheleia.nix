{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.apheleia = {
    config = "(apheleia-global-mode 1)";
    enable = true;
  };
}
