{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.usePackage.shfmt = {
    enable = true;
    custom = {
      shfmt-arguments = '''("-i" "4" "-s" "-sr")'';
      shfmt-command = ''"shfmt"'';
    };
  };
}
