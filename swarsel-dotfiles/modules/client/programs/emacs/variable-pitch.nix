{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.mixed-pitch = {
    enable = true;
    custom = {
      mixed-pitch-set-height = false;
      mixed-pitch-variable-pitch-cursor = false;
    };
    hook = [ "(text-mode . mixed-pitch-mode)" ];
  };
}
