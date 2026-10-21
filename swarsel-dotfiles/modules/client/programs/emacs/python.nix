{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.python = {
    enable = true;
    custom.python-indent-guess-indent-offset-verbose = false;
  };
}
