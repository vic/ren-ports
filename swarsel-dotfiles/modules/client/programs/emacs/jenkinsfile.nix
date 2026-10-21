{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage = {
    groovy-mode.enable = true;

    jenkinsfile-mode = {
      enable = true;
      mode = [ ''"Jenkinsfile"'' ];
    };
  };
}
