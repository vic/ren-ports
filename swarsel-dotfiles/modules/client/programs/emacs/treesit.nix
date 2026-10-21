{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init = {
    prelude = ''
      (setq treesit-enabled-modes t)
    '';

    usePackage = {
      treesit-fold = {
        config = "(global-treesit-fold-mode 1)";
        enable = true;
      };
      treesit-grammars = {
        enable = true;
        package = epkgs: epkgs.treesit-grammars.with-all-grammars;
        enableUsePackage = false;
      };
    };
  };
}
