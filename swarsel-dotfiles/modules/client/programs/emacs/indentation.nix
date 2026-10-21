{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init = {
    prelude = ''
      (setq-default indent-tabs-mode nil
                    tab-width 2)

      (setq tab-always-indent 'complete)
    '';

    usePackage.indent-bars = {
      enable = true;
      hook = [ "(prog-mode . indent-bars-mode)" ];
    };
  };
}
