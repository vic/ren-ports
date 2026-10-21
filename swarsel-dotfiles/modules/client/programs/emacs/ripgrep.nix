{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage = {
    rg.enable = true;
    wgrep = {
      enable = true;
      custom.wgrep-auto-save-buffer = true;
    };
  };
}
