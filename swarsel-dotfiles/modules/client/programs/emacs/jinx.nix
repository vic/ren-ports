{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager =
    {
      pkgs,
      ...
    }:
    {
    config = {
      programs.emacs.init.usePackage.jinx = {
        enable = true;
        bind = {
          "C-M-$" = "jinx-languages";
          "M-$" = "jinx-correct";
        };
        custom.jinx-languages = ''"en_US"'';
        hook = [
          "(text-mode . jinx-mode)"
          "(prog-mode . jinx-mode)"
          "(conf-mode . jinx-mode)"
        ];
      };
      home.packages = [
        pkgs.enchant
        pkgs.hunspellDicts.en_US
      ];
    };
  };
}
