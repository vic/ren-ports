{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.diff-hl = {
    enable = true;
    hook = [ "((prog-mode org-mode) . diff-hl-mode)" ];
    init = ''
      (diff-hl-margin-mode)
      (diff-hl-show-hunk-mouse-mode)
    '';
  };
}
