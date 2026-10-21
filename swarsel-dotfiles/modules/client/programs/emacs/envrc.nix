{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.envrc = {
    enable = true;
    hook = [ "(after-init . envrc-global-mode)" ];
  };
}
