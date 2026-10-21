{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.hcl-mode = {
    enable = true;
    custom.hcl-indent-level = 2;
    mode = [ ''"\\.hcl\\'"'' ];
  };
}
