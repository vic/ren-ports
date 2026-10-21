{ ... }:
{
  ren.aspects.app-shell-zsh = {
    homeManager =
      { config, pkgs, ... }:
      {
        home = {
          packages = [
            pkgs.sqlite-interactive
            pkgs.nix-zsh-completions
            pkgs.fzy
            pkgs.libnotify
          ];

          # This works around some logic that tries to prevent reloading env vars
          sessionVariablesExtra = ''
            unset __HM_SESS_VARS_SOURCED
            unset __HM_ZSH_SESS_VARS_SOURCED
          '';
        };

        programs.zsh = {
          enable = true;
          dotDir = "${config.xdg.configHome}/zsh";
          autosuggestion.enable = true;
          enableCompletion = true;
          completionInit = "autoload -U compinit && compinit -i";
          defaultKeymap = "emacs";
          autocd = true;
          history = {
            path = "\${XDG_DATA_HOME-$HOME/.local/share}/zsh/history";
            ignoreSpace = true;
            size = 1000000;
          };
          sessionVariables = {
            "DIRSTACKSIZE" = "20";
          };
        };
      };

    homeLinux =
      { pkgs, ... }:
      {
        programs.zsh.sessionVariables = {
          "LOCALE_ARCHIVE_2_11" = "${pkgs.glibcLocales}/lib/locale/locale-archive";
          "LOCALE_ARCHIVE_2_27" = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        };
      };

    persistHome = {
      directories = [
        ".local/share/zsh"
      ];
    };
  };
}
