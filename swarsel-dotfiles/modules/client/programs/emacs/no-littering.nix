{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.no-littering = {
    config = ''
      (setq custom-file (make-temp-file "emacs-custom-"))
      (load custom-file t)
    '';
    enable = true;
  };
}
