{ ... }:
{
  ren.aspects.app-shell-zsh.homeManager =
    { lib, pkgs, ... }:
    {
      programs.zsh = {
        plugins = [
          {
            name = "fzf-tab";
            src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
          }
          {
            name = "auto-notify";
            src = "${pkgs.local.zsh-auto-notify}/share/zsh-auto-notify/zsh-auto-notify.plugin.zsh";
          }
          {
            name = "fast-syntax-highlighting";
            src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
          }
          {
            name = "zsh-autosuggestions";
            file = "zsh-autosuggestions.zsh";
            src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
          }
          {
            name = "zsh-histdb";
            src = "${pkgs.local.zsh-histdb}/share/zsh-histdb";
          }
          {
            name = "zsh-skim-histdb";
            src = "${pkgs.local.zsh-skim-histdb}/share/zsh-skim-histdb";
          }
        ];

        syntaxHighlighting = {
          enable = true;
          highlighters = [
            "main"
            "brackets"
            "pattern"
            "regexp"
            "cursor"
            "line"
          ];
        };

        initContent = lib.mkMerge [
          (lib.mkBefore ''
            HISTDB_FILE=''${XDG_DATA_HOME-$HOME/.local/share}/zsh/history.db

            # Do this early so fast-syntax-highlighting can wrap and override this
            if autoload history-search-end; then
              zle -N history-beginning-search-backward-end history-search-end
              zle -N history-beginning-search-forward-end  history-search-end
            fi
          '')
        ];
      };
    };
}
