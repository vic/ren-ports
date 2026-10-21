{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.vterm = {
    enable = true;
    custom.vterm-tramp-shells = '''(("ssh" "'sh'"))'';
  };
}
