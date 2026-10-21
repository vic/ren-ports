{ ... }:
{
  ren.aspects.dev-shell-starship.homeManager = {
    programs.starship = {
      enable = true;
      enableTransience = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      settings = {
        add_newline = false;
        format = import ./_starship-format.nix;
        fill = {
          symbol = "─";
          style = "bold";
        };
        directory = {
          truncation_length = 0;
          format = "[ : $path]($style)[$read_only]($read_only_style) ";
          truncate_to_repo = false;
        };
        direnv.disabled = false;
        shell.disabled = false;
        shlvl = {
          disabled = false;
          threshold = 2;
          style = "bold red";
          symbol = "";
        };
        status = {
          disabled = false;
          symbol = " ";
        };
        username = {
          show_always = true;
          format = "[  $user]($style) ";
        };
        git_branch = {
          format = "[$symbol$branch]($style) ";
        };
        nix_shell = {
          format = "via [$symbol$state]($style) ";
        };
        custom.mob = {
          command = "echo $MOB_TIMER_ROOM";
          format = "[ ($output)]($style) ";
          when = "[[ -v MOB_TIMER_ROOM ]]";
        };

        # nerd-font symbols
        aws.symbol = " ";
        conda.symbol = " ";
        dart.symbol = " ";
        directory.read_only = " ";
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        git_branch.symbol = " ";
        golang.symbol = " ";
        hg_branch.symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        nim.symbol = " ";
        nix_shell.symbol = " ";
        package.symbol = "󰏗 ";
        perl.symbol = " ";
        php.symbol = " ";
        python.symbol = " ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        swift.symbol = "ﯣ ";
      };
    };
  };
}
