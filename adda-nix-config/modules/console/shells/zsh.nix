# zsh: zsh shell config
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-zsh.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe;
      inherit (addax) getExeName getExeName';

      commonShellFunctions = pkgs.stdenvNoCC.mkDerivation rec {
        name = "zsh-functions-${version}";
        version = "0.0.1";
        src = ./plugins/functions;
        phases = [ "installPhase" ];
        installPhase = lib.concatStringsSep "\n" [
          # sh
          ''
            mkdir $out
            cp $src/* $out/
            rm -f $out/default.nix
          ''
        ];
      };
    in
    {
      programs.zsh = {
        enable = true;
        # shellAliases = { };
        # history = {
        #   size = 100000;
        #   save = 100000;
        #   path = "${config.xdg.dataHome}/zsh/history";
        #   expireDuplicatesFirst = true;
        # };
        zsh-abbr = {
          enable = true;
          # globalAbbreviations = abbreviationsGlobal // { };
        };

        autocd = true;
        autosuggestion = {
          enable = true;
          strategy = [
            "completion"
            "history"
          ];
        };
        enableCompletion = true;
        oh-my-zsh = {
          enable = true;
          plugins = [
            # "command-not-found"
            # "docker"
            "fzf"
            "git"
            # "kubectl"
            "sudo"
            # "systemadmin"
            # "terraform"
            # "thefuck"
            "vi-mode"
            #"zsh-autosuggestions"
            #"fast-sytax-highlighting"
            "last-working-dir"
            "dotenv"
            "extract"
          ];
        };
        # TODO: Switch to fast-syntax-highlighting one day?
        # fastSyntaxHighlighting = {
        #   enable = true;
        #   ...
        # };
        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
          highlighters = [
            "main" # The base highlighter, and the only one active by default.
            "brackets" # Matches brackets and parenthesis.
            "pattern" # Matches user-defined patterns.
            "regexp" # Matches user-defined regular expressions.
            # "cursor" # Matches the cursor position.
            "root" # Highlights the whole command line if the current user is root.
            "line" # Applied to the whole command line.
          ];
        };
        # zplug = {
        #   enable = true;
        #   plugins = [
        #   ];
        # };
        antidote = {
          enable = true;
          plugins = [
            "Aloxaf/fzf-tab"
          ];
          useFriendlyNames = true;
        };
        plugins = [
          # {
          #   name = "powerlevel10k";
          #   src = pkgs.zsh-powerlevel10k;
          #   file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          # }
          # {
          #   name = "powerlevel10k-config";
          #   src = ./.;
          #   file = ".p10k.zsh";
          # }
          # {
          #   name = pkgs.zsh-autopair.pname;
          #   src = pkgs.zsh-autopair.src;
          # }
          {
            name = "zsh-functions";
            src = commonShellFunctions;
          }

          {
            name = "completion-sync";
            src = pkgs.fetchFromGitHub {
              owner = "BronzeDeer";
              repo = "zsh-completion-sync";
              rev = "master";
              hash = "sha256-XhZ7l8e2H1+W1oUkDrr8pQVPVbb3+1/wuu7MgXsTs+8=";
            };
          }
        ];
        siteFunctions = {
          nrn = ''
            nix run --impure nixpkgs#"$1"
          '';

          go-up-directories =
            # zsh
            ''
              local path=""
              local limit="$1"

              # Default to limit of 1.
              if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
                limit=1
              fi

              for ((i = 1; i <= limit; i++)); do
                path="../$path"
              done

              # Perform cd. Show error if cd fails.
              if ! __zoxide_z "$path"; then
                echo "Couldn't go up $limit dirs.";
              fi
            '';

          # fzf open files.
          fzf-open-edit = ''
            local files=($(${getExeName' pkgs.fzf "fzf-tmux"} --query="$1" --multi --select-1 --exit-0 --preview '${getExeName pkgs.bat} --style=numbers --color=always --line-range :500 {}' ))
            [[ -n "$files" ]] && $EDITOR "$files[@]"
          '';

        };
        initContent = lib.mkMerge [
          # fzf-tab configuration.
          (builtins.readFile ./fzf-tab-config.zsh)

          ''
            setopt globdots
          ''

          # zsh
          ''
            # TMPFIX: Until Zellij fixes completions generation and functions creation, a workaround is necessary.
            # Used workaround: https://github.com/zellij-org/zellij/issues/1933#issuecomment-2274464004.
            autoload -U +X compinit && compinit
            source <(${getExeName pkgs.zellij} setup --generate-completion zsh \
              | ${getExeName pkgs.gnused} -Ee 's/^(_(zellij) ).*/compdef \1\2/')
          ''

          # Print expanded commands after each command invocation before the output.
          ''
            if [[ $- == *i* ]]; then
              preexec(){ [ $1 != $2 ] && print -rP '%F{green}> $2%f' }
            fi
          ''

          # Print line with sparklines.
          # zsh
          ''
            # Printing colourful spark lines at the top of the terminal.
            function print_terminal_line_sparklines {
              seq 1 $(tput cols) | sort -R | ${getExe pkgs.python3Packages.sparklines} | ${getExe pkgs.lolcat}
            }

            function print_terminal_line_sparklines_newline = {
              print_terminal_line_sparklines
              echo
            }

            function clear-screen = {
              echoti clear
              print_terminal_line_sparklines_newline
              echo
              zle redisplay
              }
          ''

          # Auto-start nushell for interactive shells
          # zsh
          # ''
          #   if [[ $- == *i* ]]; then
          #     # zle -N clear-screen
          #     # print_terminal_line_sparklines

          #     exec ${getExe pkgs.nushell}
          #   fi
          # ''
        ];
      };
    };
}
