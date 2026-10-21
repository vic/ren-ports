{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.pinentry = {
    config = ''
      (pinentry-start)
      (setq epg-pinentry-mode 'loopback)
    '';
    enable = true;
  };
}
