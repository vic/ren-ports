{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage = {
    helpful = {
      enable = true;
      bind = {
        "C-h C-." = "helpful-at-point";
        "C-h f" = "helpful-callable";
        "C-h k" = "helpful-key";
        "C-h v" = "helpful-variable";
      };
      custom.help-window-select = false;
    };
    which-key = {
      enable = true;
      custom.which-key-idle-delay = 0.3;
      diminish = [ "which-key-mode" ];
      init = "(which-key-mode)";
    };
  };
}
