{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.rainbow-mode = {
    enable = true;
    hook = [ "((css-mode css-ts-mode web-mode html-mode html-ts-mode) . rainbow-mode)" ];
  };
}
