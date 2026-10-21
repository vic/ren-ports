{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.git-timemachine = {
    enable = true;
    hook = [ "(git-time-machine-mode . evil-normalize-keymaps)" ];
    init = "(setq git-timemachine-show-minibuffer-details t)";
  };
}
