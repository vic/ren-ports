{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.forge = {
    enable = true;
    after = [ "magit" ];
    init = "(setq forge-add-default-bindings nil)";
  };
}
