{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage = {
    highlight-parentheses = {
      config = ''
        (setq highlight-parentheses-colors '("black" "white" "black" "black" "black" "black" "black"))
        (setq highlight-parentheses-background-colors '("magenta" "blue" "cyan" "green" "yellow" "orange" "red"))
        (global-highlight-parentheses-mode t)
      '';
      enable = true;
    };
    rainbow-delimiters = {
      enable = true;
      hook = [ "(prog-mode . rainbow-delimiters-mode)" ];
    };
  };
}
