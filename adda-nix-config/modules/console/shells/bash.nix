# bash: bash shell config
{ ren, ... }:
{
  ren.aspects.shells-bash.homeManager =
    { lib, pkgs, ... }:
    let
      inherit (lib) getExe;
    in
    {

      programs.bash = {
        enable = true;
        shellAliases = lib.mkMerge [
          # commonShellAliases
          {
            # Bash-specific aliases.
          }
        ];
        historyFile = null;
        historySize = null;
        historyFileSize = null;
        enableCompletion = true;
        initExtra = lib.mkMerge [
          # (builtins.readFile ./fzf-tab-config.zsh)
          ''
            # Printing colourful spark lines at the top of the terminal.
            function print_terminal_line_sparklines {
                seq 1 $(tput cols) | sort -R | ${getExe pkgs.python3Packages.sparklines} | ${getExe pkgs.lolcat}
            }

            function print_terminal_line_sparklines_newline {
                print_terminal_line_sparklines
                echo
            }

            function clear-screen {
                echoti clear
                print_terminal_line_sparklines_newline
                echo
                zle redisplay
            }
            # FIXME: zle does not work for bash
            # zle -N clear-screen

            print_terminal_line_sparklines
          ''
        ];
      };
    };
}
